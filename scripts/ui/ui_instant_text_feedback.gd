extends CanvasLayer

class_name UIInstantTextFeedback

@export var label_path: NodePath
@export var container_path: NodePath
@export var camera_path: NodePath

@export var duration: float = 0.9
@export var rise_distance: float = 40.0
@export var start_alpha: float = 1.0
@export var end_alpha: float = 0.0
@export var screen_offset: Vector2 = Vector2(-80, 0)

var _label: Label
var _container: Control
var _camera: Camera2D

func _ready():
	_resolve_nodes()
	if _container:
		_container.visible = false

func show_feedback_at(world_position: Vector2, amount: int) -> void:
	_show(world_position, amount, false)

func show_feedback_at_gain(world_position: Vector2, amount: int) -> void:
	_show(world_position, amount, true)

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


