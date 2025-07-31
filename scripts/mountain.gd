extends StaticBody2D
class_name Mountain

@export var movement_speed: float = 200.0  # Speed mountain moves left
@export var spawn_y_offset: float = 500.0  # Y offset from screen height for random positioning

func _ready():
	# Add to obstacles group for collision detection
	add_to_group("obstacles")

func setup_mountain(screen_width: float, screen_height: float):
	"""Set up mountain with random Y position according to GDD"""
	# Position off-screen to the right
	var spawn_x = screen_width + 100  # Start off-screen to the right
	
	# Get sprite height for positioning calculation
	var sprite = get_node("Sprite2D")
	var texture = sprite.texture
	var sprite_height = texture.get_height()
	
	# Random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset (GDD requirement)
	var base_y = screen_height - sprite_height
	var spawn_y = randf_range(base_y, base_y + spawn_y_offset)
	
	global_position = Vector2(spawn_x, spawn_y)
	
	print("Mountain setup at position: ", global_position, " (Y range: ", base_y, " to ", base_y + spawn_y_offset, ")")

func _process(delta):
	"""Handle automatic movement and cleanup"""
	# Move left automatically
	global_position.x -= movement_speed * delta
	
	# Self-cleanup when off-screen (based on sprite width)
	var sprite = get_node("Sprite2D")
	var texture = sprite.texture
	var sprite_width = texture.get_width()
	
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
	var sprite_width = texture.get_width()
	return global_position.x + sprite_width < 0
