extends BaseObstacle
class_name Stalactite

@export var min_stalactite_height: float = 150.0  # Minimum height from top according to GDD
@export var max_stalactite_height: float = 400.0

func _ready():
	# Call parent _ready first
	super._ready()
	# Stalactites cannot carry nests according to GDD
	can_carry_nest = false

func get_spawn_y_position(_screen_height: float) -> float:
	"""Implement stalactite-specific Y positioning according to GDD"""
	# Get actual sprite height accounting for scaling applied in scene
	var actual_sprite_height = get_actual_sprite_height()
	
	# According to GDD: stalactites should spawn from (-sprite_height + minimum_stalactite_height) to 0
	var min_y = -actual_sprite_height + min_stalactite_height
	var max_y = 0  # Stalactites hang from the top of screen (Y=0)
	var spawn_y = randf_range(min_y, max_y)
	
	print("Stalactite Y positioning: scaled_height=", actual_sprite_height, " range=", min_y, " to ", max_y, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Stalactite"
