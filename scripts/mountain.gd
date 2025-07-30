extends StaticBody2D
class_name Mountain

@export var mountain_scale_min: float = 0.5  # Minimum mountain scale
@export var mountain_scale_max: float = 1.5  # Maximum mountain scale
@export var movement_speed: float = 200.0  # Speed mountain moves left

func _ready():
	# Add to obstacles group for collision detection
	add_to_group("obstacles")

func setup_mountain(screen_width: float, screen_height: float):
	"""Set up mountain with random scale and position at bottom of screen"""
	# Random scale (as per GDD requirements: 0.5 to 1.5)
	var scale_factor = randf_range(mountain_scale_min, mountain_scale_max)
	scale = Vector2(scale_factor, scale_factor)
	
	# Position at bottom of screen with top-left pivot
	var spawn_x = screen_width + 100  # Start off-screen to the right
	
	# Get sprite height to position bottom edge at screen bottom
	var sprite = get_node("Sprite2D")
	var texture = sprite.texture
	var sprite_height = texture.get_height() * scale_factor
	
	# With top-left pivot: position so bottom of sprite touches screen bottom
	var spawn_y = screen_height - sprite_height
	
	global_position = Vector2(spawn_x, spawn_y)
	
	print("Mountain setup at position: ", global_position, " with scale: ", scale_factor)

func _process(delta):
	"""Handle automatic movement and cleanup"""
	# Move left automatically
	global_position.x -= movement_speed * delta
	
	# Self-cleanup when off-screen (based on sprite width)
	var sprite = get_node("Sprite2D")
	var texture = sprite.texture
	var sprite_width = texture.get_width() * scale.x
	
	# Remove when the rightmost edge is off the left side of the screen
	if global_position.x + sprite_width < 0:
		print("Mountain ", name, " removed (off-screen)")
		queue_free()

func move_left(speed: float, delta: float):
	"""Move mountain to the left (legacy method - now handled automatically)"""
	global_position.x -= speed * delta
	
	# Return true if mountain is off-screen (for cleanup)
	var sprite = get_node("Sprite2D")
	var texture = sprite.texture
	var sprite_width = texture.get_width() * scale.x
	return global_position.x + sprite_width < 0
