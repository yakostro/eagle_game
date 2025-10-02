extends CanvasLayer

class_name UIInstantTextFeedback

@export var palette: UiPalette
@export var text_token: StringName = &"White"
@export var gain_token: StringName = &"Yellow3"
@export var lose_token: StringName = &"Red3"

@export var label_path: NodePath
@export var container_path: NodePath
@export var camera_path: NodePath

@export var duration: float = 2.0
@export var rise_distance: float = 80.0
@export var start_alpha: float = 1.0
@export var end_alpha: float = 0.0
@export var screen_offset: Vector2 = Vector2(-130, -100)

# Edge display tuning
@export var edge_vertical_margin: float = 40.0
@export var edge_horizontal_padding: float = 60.0
@export var edge_default_x_anchor: float = 0.5

var _label: Label
var _container: Control
var _camera: Camera2D

func _ready():
	_resolve_nodes()
	if _container:
		_container.visible = false
	if _label:
		_label.add_theme_color_override("font_color", _get_color(text_token))

func show_feedback_at(world_position: Vector2, amount: int) -> void:
	_show(world_position, amount, false)

func show_feedback_at_gain(world_position: Vector2, amount: int) -> void:
	_show(world_position, amount, true)

func show_feedback_at_edge(edge: int, amount: int, world_position: Vector2) -> void:
	if not _ensure_ready():
		return

	# Stop any existing tween to avoid conflicts
	var existing_tweens = get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if tween.is_valid():
			tween.kill()

	# Update text color and sign for loss at screen edge
	_label.text = "-" + str(amount)
	if _label:
		_label.add_theme_color_override("font_color", _get_color(lose_token))

	# Compute screen placement relative to camera viewport, using world X like on-screen mode
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var screen_center: Vector2 = _camera.get_screen_center_position()
	var half_width: float = width * 0.5
	var half_height: float = height * 0.5

	# Project world X to screen X and clamp to safe area, apply the same horizontal screen_offset
	var projected_x: float = screen_center.x + (world_position.x - _camera.global_position.x)
	var min_x: float = screen_center.x - half_width + edge_horizontal_padding
	var max_x: float = screen_center.x + half_width - edge_horizontal_padding
	var screen_x: float = clamp(projected_x + screen_offset.x, min_x, max_x)
	var screen_y: float = screen_center.y - half_height + edge_vertical_margin if edge == 0 else screen_center.y + half_height - edge_vertical_margin

	_container.position = Vector2(screen_x, screen_y)

	# Prepare visuals
	var modulate_color: Color = _container.modulate
	modulate_color.a = start_alpha
	_container.modulate = modulate_color
	_container.visible = true

	# Animate rise and fade in parallel
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_container, "position", _container.position + Vector2(0, -rise_distance), duration)
	tween.parallel().tween_property(_container, "modulate:a", end_alpha, duration)
	tween.finished.connect(func():
		if _container:
			_container.visible = false
	)

func _show(world_position: Vector2, amount: int, is_gain: bool) -> void:
	if not _ensure_ready():
		return

	# Update text with sign
	_label.text = ("+" if is_gain else "-") + str(amount)

	# Convert world to screen position using camera
	var screen_center: Vector2 = _camera.get_screen_center_position()
	var screen_pos: Vector2 = screen_center + (world_position - _camera.global_position)
	_container.position = screen_pos + screen_offset

	# Prepare visuals
	var modulate_color: Color = _container.modulate
	modulate_color.a = start_alpha
	_container.modulate = modulate_color
	_container.visible = true

	# Apply color based on gain/lose
	var token: StringName = gain_token if is_gain else lose_token
	if _label:
		_label.add_theme_color_override("font_color", _get_color(token))

	# Animate rise and fade in parallel
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_container, "position", _container.position + Vector2(0, -rise_distance), duration)
	tween.parallel().tween_property(_container, "modulate:a", end_alpha, duration)
	tween.finished.connect(func():
		if _container:
			_container.visible = false
	)

func _resolve_nodes() -> void:
	if container_path != NodePath(""):
		_container = get_node_or_null(container_path) as Control
	if not _container:
		_container = find_child("InstantTextContainer", true, false) as Control

	if label_path != NodePath(""):
		_label = get_node_or_null(label_path) as Label
	if not _label and _container:
		_label = _container.find_child("FeedbackLabel", true, false) as Label

	if camera_path != NodePath(""):
		_camera = get_node_or_null(camera_path) as Camera2D
	if not _camera:
		_camera = get_tree().current_scene.find_child("Camera2D", true, false) as Camera2D

func _ensure_ready() -> bool:
	return _label != null and _container != null and _camera != null

func _get_color(token: StringName) -> Color:
	if palette:
		var value = palette.get(String(token))
		if typeof(value) == TYPE_COLOR:
			return value
		var fallback = palette.get(String(text_token))
		if typeof(fallback) == TYPE_COLOR:
			return fallback
	return Color(0.890196, 0.866667, 0.909804, 1.0)


