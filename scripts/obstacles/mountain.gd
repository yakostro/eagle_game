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

	# According to GDD: height parameters are measured from screen bottom
	# So min_mountain_offset and max_mountain_offset represent absolute Y positions from bottom
	var min_y = screen_height - min_mountain_offset  # Convert from bottom-relative to absolute Y
	var max_y = screen_height - max_mountain_offset  # Convert from bottom-relative to absolute Y

	# Ensure mountains don't spawn above screen top (negative Y values)
	min_y = max(min_y, -actual_sprite_height)  # Allow slight overlap at top if needed
	max_y = max(max_y, -actual_sprite_height)

	# Ensure min is actually less than max (inverted because higher Y = lower on screen)
	if min_y > max_y:
		var temp = min_y
		min_y = max_y
		max_y = temp

	var spawn_y = randf_range(min_y, max_y)

	print("Mountain Y positioning: screen_height=", screen_height, " actual_sprite_height=", actual_sprite_height)
	print("   Height params: min_offset=", min_mountain_offset, " max_offset=", max_mountain_offset)
	print("   Y range: ", min_y, " to ", max_y, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Mountain"

func setup_mountain(screen_w: float, screen_height: float):
	"""Legacy method for backwards compatibility"""
	setup_obstacle(screen_w, screen_height)

# All movement, cleanup, and legacy methods are now handled by BaseObstacle
