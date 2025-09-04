class_name BaseObstacle
extends StaticBody2D

# Movement properties - should match eagle/world speed (as per GDD)
@export var movement_speed: float = 300.0  # Speed obstacle moves left

# Nest support - define per obstacle type
@export var can_carry_nest: bool = true

# Screen cleanup properties
var screen_width: float
var sprite_node: Sprite2D

func _ready():
	# Add to obstacles group for collision detection
	add_to_group("obstacles")
	
	# Get sprite reference for positioning and cleanup calculations
	sprite_node = get_node("Sprite2D")
	if not sprite_node:
		push_error("BaseObstacle requires a Sprite2D child node!")

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

	print(get_obstacle_type(), " setup at position: ", global_position)

func setup_obstacle_at_x_position(screen_w: float, screen_height: float, spawn_x: float):
	"""Set up obstacle at a specific X position"""
	self.screen_width = screen_w

	# Child classes must implement specific Y positioning
	var spawn_y = get_spawn_y_position(screen_height)

	global_position = Vector2(spawn_x, spawn_y)

	print(get_obstacle_type(), " setup at position: ", global_position)

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
		print(get_obstacle_type(), " ", name, " removed (off-screen)")
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

func get_actual_sprite_height() -> float:
	"""Get the actual sprite height accounting for scaling applied in the scene"""
	if not sprite_node or not sprite_node.texture:
		push_error("get_actual_sprite_height(): No sprite or texture available!")
		return 0.0
	
	var full_height = sprite_node.texture.get_height()
	# Account for both sprite scaling and root node scaling
	var total_scale_y = sprite_node.scale.y * self.scale.y
	var scaled_height = full_height * total_scale_y
	return scaled_height

func get_actual_sprite_width() -> float:
	"""Get the actual sprite width accounting for scaling applied in the scene"""
	if not sprite_node or not sprite_node.texture:
		push_error("get_actual_sprite_width(): No sprite or texture available!")
		return 0.0
	
	var full_width = sprite_node.texture.get_width()
	# Account for both sprite scaling and root node scaling
	var total_scale_x = sprite_node.scale.x * self.scale.x
	var scaled_width = full_width * total_scale_x
	return scaled_width
