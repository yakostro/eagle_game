extends BaseObstacle
class_name FloatingIsland

var minimum_top_offset: float = 100.0  # Minimum offset from top according to GDD
var minimum_bottom_offset: float = 100.0  # Minimum offset from bottom according to GDD

func _ready():
	# Call parent _ready first
	super._ready()
	# Floating islands can carry nests
	can_carry_nest = true

func get_spawn_y_position(screen_height: float) -> float:
	"""Implement floating island-specific Y positioning according to GDD"""
	# Get actual sprite height accounting for scaling applied in scene
	var actual_sprite_height = get_actual_sprite_height()
	
	# Desired Y range where the TOP of the sprite stays >= minimum_top_offset
	# and the BOTTOM of the sprite stays <= screen_height - minimum_bottom_offset.
	# This produces available vertical span for the sprite's top position.
	var min_y = minimum_top_offset
	var max_y = screen_height - minimum_bottom_offset - actual_sprite_height
	
	# If stage settings and sprite height leave no room, clamp to a safe span.
	# We create at least a small selectable range to avoid warnings and keep islands on-screen.
	if max_y <= min_y:
		var safe_top = clamp(minimum_top_offset, 0.0, max(0.0, screen_height - actual_sprite_height))
		var safe_bottom = max(safe_top + 1.0, screen_height - minimum_bottom_offset - actual_sprite_height)
		min_y = safe_top
		max_y = safe_bottom
	
	var spawn_y = randf_range(min_y, max_y)
	
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "FloatingIsland"
