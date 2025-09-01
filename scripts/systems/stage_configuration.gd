class_name StageConfiguration
extends Resource

## Resource class that defines all parameters for a game stage
## Used by StageManager to control difficulty progression and spawner behavior

# Stage Identity
@export_group("Stage Info")
@export var stage_number: int = 1
@export var stage_name: String = "Tutorial Stage"

# World Parameters
@export_group("World Settings")
@export var world_speed: float = 300.0

# Obstacle Parameters
@export_group("Obstacle Settings")
@export var mountain_weight: int = 10
@export var stalactite_weight: int = 0  # 0 = disabled
@export var floating_island_weight: int = 5

# Obstacle Height Ranges (pixels) - specific to each obstacle type
@export_subgroup("Mountain Heights")
@export var mountain_min_height: float = 0.0
@export var mountain_max_height: float = 400.0

@export_subgroup("Stalactite Heights") 
@export var stalactite_min_height: float = -300.0
@export var stalactite_max_height: float = 0.0

@export_subgroup("Floating Island Offsets")
@export var floating_island_minimum_top_offset: float = 500.0
@export var floating_island_minimum_bottom_offset: float = 300.0

# Obstacle Distance Parameters (pixels)
@export_subgroup("Distance Settings")
@export var min_obstacle_distance: float = 400.0
@export var max_obstacle_distance: float = 800.0
@export_range(0.0, 1.0) var same_obstacle_repeat_chance: float = 0.1  # 10% chance

# Fish Parameters
@export_group("Fish Settings")
@export var fish_enabled: bool = false
@export var fish_min_spawn_interval: float = 3.0
@export var fish_max_spawn_interval: float = 7.0

# Nest Parameters
@export_group("Nest Settings")
@export var nests_enabled: bool = false
@export var nest_min_skipped_obstacles: int = 3
@export var nest_max_skipped_obstacles: int = 6

# Stage Completion Condition
@export_group("Stage Completion")
@export var completion_type: CompletionType = CompletionType.TIMER
@export var completion_value: float = 10.0  # 10 seconds or 10 nests

enum CompletionType {
	TIMER,      ## Complete after X seconds
	NESTS       ## Complete after X nests spawned
}

## Get a formatted string describing this stage for debug purposes
func get_debug_info() -> String:
	var info = "Stage %d: %s\n" % [stage_number, stage_name]
	info += "  World Speed: %.1f\n" % world_speed
	info += "  Obstacles: M=%d S=%d I=%d\n" % [mountain_weight, stalactite_weight, floating_island_weight]
	
	# Show height ranges for enabled obstacles
	if mountain_weight > 0:
		info += "    Mountain Heights: %.1f to %.1f\n" % [mountain_min_height, mountain_max_height]
	if stalactite_weight > 0:
		info += "    Stalactite Heights: %.1f to %.1f\n" % [stalactite_min_height, stalactite_max_height]
	if floating_island_weight > 0:
		info += "    Floating Island Offsets: top=%.1f, bottom=%.1f\n" % [floating_island_minimum_top_offset, floating_island_minimum_bottom_offset]
	
	info += "  Fish: %s" % ("ON" if fish_enabled else "OFF")
	if fish_enabled:
		info += " (%.1f-%.1fs)" % [fish_min_spawn_interval, fish_max_spawn_interval]
	info += "\n"
	info += "  Nests: %s" % ("ON" if nests_enabled else "OFF")
	if nests_enabled:
		info += " (%d-%d obstacles)" % [nest_min_skipped_obstacles, nest_max_skipped_obstacles]
	info += "\n"
	
	var completion_desc = "Timer (%.1fs)" if completion_type == CompletionType.TIMER else "Nests (%.0f)"
	info += "  Completion: " + completion_desc % completion_value
	
	return info

## Validate that all stage parameters are reasonable
func validate_parameters() -> bool:
	var is_valid = true
	
	# Check basic ranges
	if world_speed <= 0:
		push_error("Stage %d: world_speed must be positive" % stage_number)
		is_valid = false
	
	if min_obstacle_distance >= max_obstacle_distance:
		push_error("Stage %d: min_obstacle_distance must be less than max_obstacle_distance" % stage_number)
		is_valid = false
	
	# Check obstacle height ranges
	if mountain_weight > 0 and mountain_min_height >= mountain_max_height:
		push_error("Stage %d: mountain_min_height must be less than mountain_max_height" % stage_number)
		is_valid = false
	
	if stalactite_weight > 0 and stalactite_min_height >= stalactite_max_height:
		push_error("Stage %d: stalactite_min_height must be less than stalactite_max_height" % stage_number)
		is_valid = false
	
	if floating_island_weight > 0 and floating_island_minimum_top_offset <= floating_island_minimum_bottom_offset:
		push_error("Stage %d: floating_island_minimum_top_offset must be greater than floating_island_minimum_bottom_offset" % stage_number)
		is_valid = false
	
	if fish_enabled and fish_min_spawn_interval >= fish_max_spawn_interval:
		push_error("Stage %d: fish_min_spawn_interval must be less than fish_max_spawn_interval" % stage_number)
		is_valid = false
	
	if nests_enabled and nest_min_skipped_obstacles >= nest_max_skipped_obstacles:
		push_error("Stage %d: nest_min_skipped_obstacles must be less than nest_max_skipped_obstacles" % stage_number)
		is_valid = false
	
	if completion_value <= 0:
		push_error("Stage %d: completion_value must be positive" % stage_number)
		is_valid = false
	
	return is_valid
