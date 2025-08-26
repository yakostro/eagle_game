extends BaseObstacle
class_name Mountain

@export var min_mountain_offset: float = 300.0     # Minimum additional offset from base position  
@export var max_mountain_offset: float = 500.0  # Maximum additional offset (GDD specifies 500px)

func _ready():
	# Call parent _ready first
	super._ready()

func get_spawn_y_position(screen_height: float) -> float:
	"""Implement mountain-specific Y positioning according to GDD"""
	# Get actual sprite height accounting for scaling applied in scene
	var actual_sprite_height = get_actual_sprite_height()
	
	# According to GDD: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset
	var base_y = screen_height - actual_sprite_height
	var min_y = base_y + min_mountain_offset  # SCREEN_HEIGHT - SPRITE_HEIGHT + min_offset
	var max_y = base_y + max_mountain_offset  # SCREEN_HEIGHT - SPRITE_HEIGHT + max_offset
	
	var spawn_y = randf_range(min_y, max_y)
	
	print("Mountain Y positioning: scaled_height=", actual_sprite_height, " base_y=", base_y, " range=", min_y, " to ", max_y, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Mountain"

func setup_mountain(screen_w: float, screen_height: float):
	"""Legacy method for backwards compatibility"""
	setup_obstacle(screen_w, screen_height)

# All movement, cleanup, and legacy methods are now handled by BaseObstacle
