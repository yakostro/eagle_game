extends BaseObstacle
class_name Mountain

# Positioning now controlled by GameBalance singleton
# @export var spawn_y_offset: float = 500.0  # Now using GameBalance.mountain_y_position_offset

func _ready():
	# Call parent _ready first
	super._ready()

func get_spawn_y_position(screen_height: float) -> float:
	"""Implement mountain-specific Y positioning according to GDD"""
	# Get sprite height for positioning calculation
	var texture = sprite_node.texture
	var sprite_height = texture.get_height()
	
	# Random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset (GDD requirement)
	var base_y = screen_height - sprite_height
	var spawn_y = randf_range(base_y, base_y + GameBalance.mountain_y_position_offset)
	
	print("Mountain Y positioning: base=", base_y, " range=", base_y, " to ", base_y + GameBalance.mountain_y_position_offset, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Mountain"

func setup_mountain(screen_w: float, screen_height: float):
	"""Legacy method for backwards compatibility"""
	setup_obstacle(screen_w, screen_height)

# All movement, cleanup, and legacy methods are now handled by BaseObstacle
