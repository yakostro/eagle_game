class_name StageConfiguration
extends Resource

## Resource class that defines all parameters for a game stage
## Used by StageManager to control difficulty progression and spawner behavior

# Stage Identity
@export var stage_number: int = 1
@export var stage_name: String = "Tutorial Stage"

# World Parameters
@export var world_speed: float = 300.0

# Obstacle Parameters
@export var mountain_weight: int = 10
@export var stalactite_weight: int = 0  # 0 = disabled
@export var floating_island_weight: int = 5

# Obstacle Height Ranges (pixels) - specific to each obstacle type
@export var mountain_min_height: float = 0.0
@export var mountain_max_height: float = 400.0
@export var stalactite_min_height: float = -300.0
@export var stalactite_max_height: float = 0.0
@export var floating_island_minimum_top_offset: float = 100.0
@export var floating_island_minimum_bottom_offset: float = 100.0

# Distance Between Obstacles
@export var min_obstacle_distance: float = 600.0
@export var max_obstacle_distance: float = 1200.0
@export var same_obstacle_repeat_chance: float = 0.3  # 30% chance to repeat same obstacle

# Fish System
@export var fish_enabled: bool = false
@export var fish_min_spawn_interval: float = 3.0
@export var fish_max_spawn_interval: float = 7.0

# Nest System
@export var nests_enabled: bool = false
@export var nest_min_skipped_obstacles: int = 3
@export var nest_max_skipped_obstacles: int = 6
@export var nest_visibility_offset: float = 50.0  # Pixels from screen bottom to keep nests visible

# Stage Completion Parameters
enum CompletionType { TIMER, NESTS_SPAWNED }
@export var completion_type: CompletionType = CompletionType.TIMER
@export var completion_value: float = 10.0  # seconds for timer, count for nests

# VALIDATION AND DEBUG METHODS ===============================================

func validate_parameters() -> bool:
	"""Validate that all stage parameters are within acceptable ranges"""
	if stage_number < 1:
		push_error("StageConfiguration: Invalid stage_number (%d)" % stage_number)
		return false
	
	if world_speed <= 0:
		push_error("StageConfiguration: Invalid world_speed (%.1f)" % world_speed)
		return false
		
	if completion_value <= 0:
		push_error("StageConfiguration: Invalid completion_value (%.1f)" % completion_value)
		return false
		
	if min_obstacle_distance >= max_obstacle_distance:
		push_error("StageConfiguration: min_obstacle_distance >= max_obstacle_distance")
		return false
	
	return true

func get_debug_info() -> String:
	"""Return a formatted string with all stage parameters for debugging"""
	var info = []
	info.append("=== STAGE %d: %s ===" % [stage_number, stage_name])
	info.append("World Speed: %.1f" % world_speed)
	info.append("Weights - Mountain: %d, Stalactite: %d, Island: %d" % [mountain_weight, stalactite_weight, floating_island_weight])
	info.append("Mountain Heights: %.1f - %.1f" % [mountain_min_height, mountain_max_height])
	info.append("Stalactite Heights: %.1f - %.1f" % [stalactite_min_height, stalactite_max_height])
	info.append("Island Offsets: Top %.1f, Bottom %.1f" % [floating_island_minimum_top_offset, floating_island_minimum_bottom_offset])
	info.append("Distance: %.1f - %.1f" % [min_obstacle_distance, max_obstacle_distance])
	info.append("Fish: %s (%.1f-%.1fs)" % ["ON" if fish_enabled else "OFF", fish_min_spawn_interval, fish_max_spawn_interval])
	info.append("Nests: %s (%d-%d skipped)" % ["ON" if nests_enabled else "OFF", nest_min_skipped_obstacles, nest_max_skipped_obstacles])
	
	var completion_str = "Timer: %.1fs" % completion_value if completion_type == CompletionType.TIMER else "Nests: %d" % int(completion_value)
	info.append("Completion: %s" % completion_str)
	
	return "\n".join(info)
