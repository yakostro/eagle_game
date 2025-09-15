class_name UIOffscreenNestIndicator
extends Control

## Off-screen nest indicator that shows a blinking icon at the right edge when nest is spawned off-screen

@export var icon_texture: Texture2D  # Nest icon texture
@export var icon_size: Vector2 = Vector2(48, 48)  # Size of the indicator icon
@export var right_margin: float = 32.0  # Distance from right screen edge
@export var vertical_padding: float = 50.0  # Top/bottom safe margins
@export var blink_duration: float = 1.0  # Time for one fade in/out cycle
@export var min_hide_lead_time: float = 0.3  # Hide indicator this early before nest appears

# Node path exports (prefer NodePath over direct references)
@export var camera_path: NodePath
@export var nest_spawner_path: NodePath
@export var palette_resource: UiPalette  # UI palette for colors

# Internal references
var camera: Camera2D
var nest_spawner: NestSpawner
var icon_rect: TextureRect
var tween: Tween

# State tracking
var is_showing: bool = false
var current_nest_world_position: Vector2
var current_nest: Node

func _ready():
	# Get node references
	if camera_path:
		camera = get_node(camera_path) as Camera2D
	if nest_spawner_path:
		nest_spawner = get_node(nest_spawner_path) as NestSpawner
	
	# Validate required references
	if not camera:
		print("❌ UIOffscreenNestIndicator: Camera2D not found at path: ", camera_path)
		return
	if not nest_spawner:
		print("❌ UIOffscreenNestIndicator: NestSpawner not found at path: ", nest_spawner_path)
		return
	
	# Setup UI structure
	_setup_ui()
	
	# Connect to nest spawner signals
	nest_spawner.nest_spawned.connect(_on_nest_spawned)
	
	print("🏠 Off-screen nest indicator initialized")

func _setup_ui():
	"""Create the UI structure for the indicator"""
	# Set up this control to fill the screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create icon TextureRect
	icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon_texture
	icon_rect.custom_minimum_size = icon_size
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false  # Start hidden
	
	# Apply palette colors if available
	if palette_resource:
		icon_rect.modulate = palette_resource.White
	
	add_child(icon_rect)
	
	print("🏠 UI structure created for off-screen nest indicator")

func _process(_delta):
	"""Update indicator position and visibility each frame"""
	if not is_showing or not current_nest:
		return
	
	# Check if nest is still off-screen to the right
	if _is_nest_visible():
		_hide_indicator()
		return
	
	# Update indicator Y position based on current nest world position
	_update_indicator_position()

func _on_nest_spawned(nest: Node):
	"""Handle nest spawned signal from NestSpawner"""
	if not nest:
		return
	
	current_nest = nest
	
	# Get nest world position (it's a child of obstacle, so use global_position)
	current_nest_world_position = nest.global_position
	
	# Show indicator immediately when nest spawns (regardless of initial position)
	_show_indicator()
	
	print("🏠 Nest spawned at world position: ", current_nest_world_position, " - Indicator shown immediately")

func _is_nest_visible() -> bool:
	"""Check if the current nest is visible on screen"""
	if not current_nest or not camera:
		return true  # Assume visible if we can't check
	
	# Get camera bounds in world space
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_global_pos = camera.global_position
	var zoom = camera.zoom
	
	# Calculate camera's right edge in world space
	var half_viewport_width = (viewport_size.x * 0.5) / zoom.x
	var camera_right_edge = camera_global_pos.x + half_viewport_width
	
	# Add small buffer for "about to enter view" logic
	var visibility_buffer = min_hide_lead_time * 200.0  # Approximate pixels per lead time
	
	# Nest is visible if its X position is within camera bounds (with buffer)
	return current_nest.global_position.x <= (camera_right_edge + visibility_buffer)

func _show_indicator():
	"""Show and start blinking the indicator"""
	if is_showing:
		return
	
	is_showing = true
	icon_rect.visible = true
	_update_indicator_position()
	_start_blinking()
	
	print("🏠 Showing off-screen nest indicator")

func _hide_indicator():
	"""Hide the indicator and stop blinking"""
	if not is_showing:
		return
	
	is_showing = false
	icon_rect.visible = false
	_stop_blinking()
	
	# Clear current nest reference
	current_nest = null
	
	print("🏠 Hiding off-screen nest indicator")

func _update_indicator_position():
	"""Update the indicator position based on nest world Y and camera"""
	if not camera or not current_nest:
		return
	
	# Get viewport dimensions
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Account for nest's visual offset and scale
	# Nest's Animation node is at (0, -59.25) relative to nest root, scaled by 0.6
	var nest_visual_offset = -59.25 * 0.6  # Visual center offset from nest root
	
	# Calculate nest's visual center world position
	var nest_visual_world_y = current_nest.global_position.y + nest_visual_offset
	
	# Project nest visual center Y to screen space
	var nest_visual_pos = Vector2(current_nest.global_position.x, nest_visual_world_y)
	var nest_screen_pos = camera.to_local(nest_visual_pos)
	var zoom = camera.zoom
	
	# Convert to viewport coordinates
	var viewport_y = (viewport_size.y * 0.5) + (nest_screen_pos.y * zoom.y)
	
	# Clamp Y within vertical padding
	viewport_y = clamp(viewport_y, vertical_padding, viewport_size.y - vertical_padding)
	
	# Position at right edge with margin, center the icon on the target Y
	var indicator_x = viewport_size.x - right_margin - (icon_size.x * 0.5)
	var indicator_y = viewport_y - (icon_size.y * 0.5)
	
	icon_rect.position = Vector2(indicator_x, indicator_y)

func _start_blinking():
	"""Start the blinking animation"""
	_stop_blinking()  # Stop any existing tween
	
	tween = create_tween()
	tween.set_loops()  # Loop indefinitely
	
	# Fade out, then fade in
	tween.tween_property(icon_rect, "modulate:a", 0.3, blink_duration * 0.5)
	tween.tween_property(icon_rect, "modulate:a", 1.0, blink_duration * 0.5)

func _stop_blinking():
	"""Stop the blinking animation"""
	if tween:
		tween.kill()
		tween = null
	
	# Reset to full opacity
	if icon_rect:
		icon_rect.modulate.a = 1.0
