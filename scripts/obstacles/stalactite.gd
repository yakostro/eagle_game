extends BaseObstacle
class_name Stalactite

# Positioning now controlled by GameBalance singleton
# @export var minimum_stalactite_height: float = 300.0  # Now using GameBalance.stalactite_minimum_height

func _ready():
	# Call parent _ready first
	super._ready()
	# Stalactites cannot carry nests according to GDD
	can_carry_nest = false

func get_spawn_y_position(_screen_height: float) -> float:
	"""Implement stalactite-specific Y positioning according to GDD"""
	# Get sprite height for positioning calculation
	var texture = sprite_node.texture
	var sprite_height = texture.get_height()
	
	# Random Y position:
	var min_y = -sprite_height + GameBalance.stalactite_minimum_height
	var max_y = 0
	var spawn_y = randf_range(min_y, max_y)
	
	print("Stalactite Y positioning: sprite_height=", sprite_height, " range=", min_y, " to ", max_y, " chosen=", spawn_y)
	return spawn_y

func get_obstacle_type() -> String:
	"""Return obstacle type for debugging"""
	return "Stalactite"
