extends BaseObstacle
class_name Mountain

@export var min_mountain_height: float = 500.0
@export var max_mountain_height: float = 500.0  # Maximum height offset from screen height for random positioning

func _ready():
	# Call parent _ready first
	super._ready()

func get_spawn_y_position(screen_height: float) -> float:
	"""Implement mountain-specific Y positioning according to GDD"""
	# Get sprite height for positioning calculation
	#var texture = sprite_node.texture
	#var sprite_height = texture.get_height()
	
	# Random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset (GDD requirement)
	var min_y = screen_height - min_mountain_height
	var max_y = screen_height - max_mountain_height
	var spawn_y = randf_range(min_y, max_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Mountain"

func setup_mountain(screen_w: float, screen_height: float):
	"""Legacy method for backwards compatibility"""
	setup_obstacle(screen_w, screen_height)

# All movement, cleanup, and legacy methods are now handled by BaseObstacle
