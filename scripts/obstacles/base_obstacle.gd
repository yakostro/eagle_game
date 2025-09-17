class_name BaseObstacle
extends StaticBody2D

# Movement properties - should match eagle/world speed (as per GDD)
@export var movement_speed: float = 300.0  # Speed obstacle moves left

# Nest support - define per obstacle type
@export var can_carry_nest: bool = true

# Screen cleanup properties
var screen_width: float
var sprite_node: Sprite2D
var _cached_actual_sprite_width: float = -1.0
var _cached_actual_sprite_height: float = -1.0

func _ready():
	# Add to obstacles group for collision detection
	add_to_group("obstacles")
	
	# Get sprite reference for positioning and cleanup calculations
	sprite_node = get_node("Sprite2D")
	if not sprite_node:
		push_error("BaseObstacle requires a Sprite2D child node!")
	else:
		# Precompute cached sprite dimensions to avoid per-frame texture queries
		if sprite_node.texture:
			var full_width = sprite_node.texture.get_width()
			var full_height = sprite_node.texture.get_height()
			var total_scale_x = sprite_node.scale.x * self.scale.x
			var total_scale_y = sprite_node.scale.y * self.scale.y
			_cached_actual_sprite_width = full_width * total_scale_x
			_cached_actual_sprite_height = full_height * total_scale_y

func _process(delta):
	"""Handle automatic movement and cleanup"""
	# Move left automatically
	global_position.x -= movement_speed * delta
	
	# Self-cleanup when off-screen
	cleanup_when_offscreen()

func setup_obstacle(screen_w: float, screen_height: float):
	"""Set up obstacle with positioning - must be implemented by child classes"""
	self.screen_width = screen_w

	# Position off-screen to the right (common for all obstacles)
	var spawn_x = screen_w + 100  # Start off-screen to the right

	# Child classes must implement specific Y positioning
	var spawn_y = get_spawn_y_position(screen_height)

	global_position = Vector2(spawn_x, spawn_y)



func get_spawn_y_position(_screen_height: float) -> float:
	"""Abstract method - must be implemented by child classes"""
	push_error("get_spawn_y_position() must be implemented by child class!")
	return 0.0

func get_obstacle_type() -> String:
	"""Abstract method - return obstacle type name for debugging"""
	push_error("get_obstacle_type() must be implemented by child class!")
	return "Unknown"

func cleanup_when_offscreen():
	"""Remove obstacle when it's completely off the left side of screen"""
	if not sprite_node or not sprite_node.texture:
		return
	
	var actual_sprite_width = get_actual_sprite_width()
	
	# Remove when the rightmost edge is off the left side of the screen
	if global_position.x + actual_sprite_width < 0:
		queue_free()

func move_left(speed: float, delta: float):
	"""Legacy method for backwards compatibility - now handled automatically"""
	global_position.x -= speed * delta
	
	# Return true if obstacle is off-screen (for cleanup)
	if not sprite_node or not sprite_node.texture:
		return false
	
	var actual_sprite_width = get_actual_sprite_width()
	return global_position.x + actual_sprite_width < 0

func set_movement_speed(speed: float):
	"""Allow spawner to set movement speed (for shared eagle/world speed)"""
	movement_speed = speed

func get_nest_placeholder() -> Marker2D:
	"""Get the nest placeholder node if it exists"""
	return get_node_or_null("NestPlaceholder")

func has_nest_placeholder() -> bool:
	"""Check if this obstacle can actually place a nest"""
	return can_carry_nest and get_nest_placeholder() != null

func get_all_nest_placeholders() -> Array[Marker2D]:
	"""Get all nest placeholder nodes in this obstacle"""
	var placeholders: Array[Marker2D] = []

	# Find all nodes that start with "NestPlaceholder"
	for child in get_children():
		if child is Marker2D and child.name.begins_with("NestPlaceholder"):
			placeholders.append(child)

	return placeholders

func get_visible_nest_placeholders(screen_height: float, bottom_offset: float) -> Array[Marker2D]:
	"""Get nest placeholders that would place nests within visible screen area"""
	var all_placeholders = get_all_nest_placeholders()
	var visible_placeholders: Array[Marker2D] = []

	# Calculate obstacle's current global position
	# Note: This assumes the obstacle is already positioned when called
	for placeholder in all_placeholders:
		# Get placeholder's global Y position
		var placeholder_global_y = global_position.y + placeholder.position.y

		# Check if placeholder would put nest above the visibility threshold
		if placeholder_global_y < screen_height - bottom_offset:
			visible_placeholders.append(placeholder)

	return visible_placeholders

func has_visible_nest_placeholders(screen_height: float, bottom_offset: float) -> bool:
	"""Check if this obstacle has any nest placeholders that would be visible"""
	return can_carry_nest and not get_visible_nest_placeholders(screen_height, bottom_offset).is_empty()

func get_actual_sprite_height() -> float:
	"""Get the actual sprite height accounting for scaling applied in the scene"""
	if not sprite_node or not sprite_node.texture:
		push_error("get_actual_sprite_height(): No sprite or texture available!")
		return 0.0
	
	# Use cached value if available
	if _cached_actual_sprite_height > 0.0:
		return _cached_actual_sprite_height
	
	var full_height = sprite_node.texture.get_height()
	# Account for both sprite scaling and root node scaling
	var total_scale_y = sprite_node.scale.y * self.scale.y
	var scaled_height = full_height * total_scale_y
	_cached_actual_sprite_height = scaled_height
	return _cached_actual_sprite_height

func get_actual_sprite_width() -> float:
	"""Get the actual sprite width accounting for scaling applied in the scene"""
	if not sprite_node or not sprite_node.texture:
		push_error("get_actual_sprite_width(): No sprite or texture available!")
		return 0.0
	
	# Use cached value if available
	if _cached_actual_sprite_width > 0.0:
		return _cached_actual_sprite_width
	
	var full_width = sprite_node.texture.get_width()
	# Account for both sprite scaling and root node scaling
	var total_scale_x = sprite_node.scale.x * self.scale.x
	var scaled_width = full_width * total_scale_x
	_cached_actual_sprite_width = scaled_width
	return _cached_actual_sprite_width
