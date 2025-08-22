extends BaseObstacle
class_name FloatingIsland

@export var minimum_top_offset: float = 100.0  # Minimum offset from top according to GDD
@export var minimum_bottom_offset: float = 100.0  # Minimum offset from bottom according to GDD

func _ready():
	# Call parent _ready first
	super._ready()
	# Floating islands can carry nests
	can_carry_nest = true

func get_spawn_y_position(screen_height: float) -> float:
	"""Implement floating island-specific Y positioning according to GDD"""
	# Get actual sprite height accounting for scaling applied in scene
	var actual_sprite_height = get_actual_sprite_height()
	
	# Random Y position: from minimum_top_offset to minimum_bottom_offset + sprite_height (GDD requirement)
	var min_y = minimum_top_offset
	var max_y = screen_height - minimum_bottom_offset - actual_sprite_height
	
	# Ensure we have a valid range
	if max_y <= min_y:
		push_warning("FloatingIsland: Invalid Y range, using fallback positioning")
		max_y = min_y + 100  # Fallback to avoid errors
	
	var spawn_y = randf_range(min_y, max_y)
	
	print("FloatingIsland Y positioning: scaled_height=", actual_sprite_height, " range=", min_y, " to ", max_y, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "FloatingIsland"
