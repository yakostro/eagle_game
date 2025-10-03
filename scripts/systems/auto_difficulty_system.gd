class_name AutoDifficultySystem
extends RefCounted

## Auto-Difficulty System for Eagle Game
## 
## This system provides endless difficulty scaling after manual stages complete.
## Uses percentage-based increases with safety caps to ensure fair but challenging gameplay.

# Configuration resource
var config: AutoDifficultyConfiguration

# Progression state
var progression_timer: float = 0.0
var difficulty_level: int = 0  # How many progression intervals have passed

# Base values (set when auto-difficulty starts, typically from Stage 6)
var base_world_speed: float = 400.0
var base_min_obstacle_distance: float = 400.0
var base_max_obstacle_distance: float = 800.0
var base_fish_min_interval: float = 3.0
var base_fish_max_interval: float = 7.0
var base_nest_min_skipped: int = 3
var base_nest_max_skipped: int = 6
var base_stalactite_weight: int = 10
var base_mountain_weight: int = 10
var base_island_weight: int = 5
var base_mountain_min_height: float = 350.0
var base_mountain_max_height: float = 600.0
var base_stalactite_min_height: float = 200.0
var base_stalactite_max_height: float = 500.0
var base_island_min_top_offset: float = 100.0
var base_island_min_bottom_offset: float = 100.0

# Signals
signal difficulty_increased(new_level: int)
signal parameter_capped(parameter_name: String, capped_value: float)

func _init(config_resource: AutoDifficultyConfiguration = null):
	if config_resource:
		config = config_resource
	else:
		# Load default configuration
		config = load("res://configs/auto_difficulty_config.tres")
	
	if not config:
		push_error("AutoDifficultySystem: Could not load configuration!")
		return
	
	if not config.validate():
		push_error("AutoDifficultySystem: Invalid configuration!")
		return
	
	print("AutoDifficultySystem initialized with config: ", config.get_summary())

## Initialize the auto-difficulty system with base values from the final manual stage
func initialize_with_base_config(base_config: StageConfiguration):
	print("AutoDifficultySystem: Initializing with base config from stage ", base_config.stage_number)
	
	# Store base values for percentage calculations
	base_world_speed = base_config.world_speed
	base_min_obstacle_distance = base_config.min_obstacle_distance
	base_max_obstacle_distance = base_config.max_obstacle_distance
	base_fish_min_interval = base_config.fish_min_spawn_interval
	base_fish_max_interval = base_config.fish_max_spawn_interval
	base_nest_min_skipped = base_config.nest_min_skipped_obstacles
	base_nest_max_skipped = base_config.nest_max_skipped_obstacles
	base_stalactite_weight = base_config.stalactite_weight
	base_mountain_weight = base_config.mountain_weight
	base_island_weight = base_config.floating_island_weight
	base_mountain_min_height = base_config.mountain_min_height
	base_mountain_max_height = base_config.mountain_max_height
	base_stalactite_min_height = base_config.stalactite_min_height
	base_stalactite_max_height = base_config.stalactite_max_height
	base_island_min_top_offset = base_config.floating_island_minimum_top_offset
	base_island_min_bottom_offset = base_config.floating_island_minimum_bottom_offset
	
	# Reset progression
	progression_timer = 0.0
	difficulty_level = 0
	
	print("AutoDifficultySystem: Base values set - Speed: ", base_world_speed, 
		  ", Min Distance: ", base_min_obstacle_distance)

## Update the auto-difficulty system (call this every frame)
func update(delta: float):
	if not config:
		return
		
	progression_timer += delta
	
	# Check if it's time for a difficulty increase
	if progression_timer >= config.progression_interval:
		progression_timer = 0.0
		difficulty_level += 1
		print("AutoDifficultySystem: Difficulty increased to level ", difficulty_level)
		difficulty_increased.emit(difficulty_level)

## Generate a modified stage configuration with auto-difficulty applied
func get_modified_config() -> StageConfiguration:
	if not config:
		push_error("AutoDifficultySystem: No configuration loaded!")
		return null
		
	var stage_config = StageConfiguration.new()
	
	# Set basic stage info
	stage_config.stage_number = 100 + difficulty_level  # Auto-difficulty stages are 100+
	stage_config.stage_name = "Auto-Difficulty Level " + str(difficulty_level)
	
	# Apply speed scaling
	var speed_multiplier = 1.0 + (config.speed_increase_rate * difficulty_level)
	speed_multiplier = min(speed_multiplier, config.max_speed_multiplier)
	stage_config.world_speed = base_world_speed * speed_multiplier
	
	if speed_multiplier >= config.max_speed_multiplier:
		parameter_capped.emit("world_speed", stage_config.world_speed)
	
	# Apply obstacle weight progression (all obstacle types now scale)
	var mountain_weight = base_mountain_weight * (1.0 + config.mountain_weight_increase_rate * difficulty_level)
	mountain_weight = min(mountain_weight, config.max_obstacle_weight)
	stage_config.mountain_weight = int(mountain_weight)
	
	var island_weight = base_island_weight * (1.0 + config.island_weight_increase_rate * difficulty_level)
	island_weight = min(island_weight, config.max_obstacle_weight)
	stage_config.floating_island_weight = int(island_weight)
	
	# Increase stalactite weight over time (using both old and new system for compatibility)
	var stalactite_weight = base_stalactite_weight + (config.stalactite_weight_increase * difficulty_level)
	stalactite_weight = min(stalactite_weight, config.max_stalactite_weight)
	stage_config.stalactite_weight = int(stalactite_weight)
	
	if mountain_weight >= config.max_obstacle_weight:
		parameter_capped.emit("mountain_weight", mountain_weight)
	if island_weight >= config.max_obstacle_weight:
		parameter_capped.emit("island_weight", island_weight)
	if stalactite_weight >= config.max_stalactite_weight:
		parameter_capped.emit("stalactite_weight", stalactite_weight)
	
	# Apply height progression (make obstacles taller and more dangerous)
	var mountain_height_multiplier = 1.0 + (config.mountain_height_increase_rate * difficulty_level)
	mountain_height_multiplier = min(mountain_height_multiplier, config.max_mountain_height_multiplier)
	stage_config.mountain_min_height = base_mountain_min_height * mountain_height_multiplier
	stage_config.mountain_max_height = base_mountain_max_height * mountain_height_multiplier
	
	var stalactite_height_multiplier = 1.0 + (config.stalactite_height_increase_rate * difficulty_level)
	stalactite_height_multiplier = min(stalactite_height_multiplier, config.max_stalactite_height_multiplier)
	stage_config.stalactite_min_height = base_stalactite_min_height * stalactite_height_multiplier
	stage_config.stalactite_max_height = base_stalactite_max_height * stalactite_height_multiplier
	
	# Keep island offsets constant for now (could be made configurable later)
	stage_config.floating_island_minimum_top_offset = base_island_min_top_offset
	stage_config.floating_island_minimum_bottom_offset = base_island_min_bottom_offset
	
	if mountain_height_multiplier >= config.max_mountain_height_multiplier:
		parameter_capped.emit("mountain_height", stage_config.mountain_max_height)
	if stalactite_height_multiplier >= config.max_stalactite_height_multiplier:
		parameter_capped.emit("stalactite_height", stage_config.stalactite_max_height)
	
	# Apply distance scaling (shorter distances = faster spawning)
	var distance_multiplier = 1.0 - (config.spawn_rate_increase * difficulty_level * 0.5)  # Slower progression
	distance_multiplier = max(distance_multiplier, config.min_distance_multiplier)
	
	stage_config.min_obstacle_distance = base_min_obstacle_distance * distance_multiplier
	stage_config.max_obstacle_distance = base_max_obstacle_distance * distance_multiplier
	
	if distance_multiplier <= config.min_distance_multiplier:
		parameter_capped.emit("obstacle_distance", stage_config.min_obstacle_distance)
	
	# Keep same obstacle repeat chance
	stage_config.same_obstacle_repeat_chance = 0.1
	
	# Apply fish scarcity scaling (make fish scarcer over time, but preserve boost system)
	stage_config.fish_enabled = true
	
	# Use new fish availability decrease system - this makes fish spawn LESS frequently (longer intervals)
	var fish_availability_multiplier = 1.0 + (config.fish_availability_decrease_rate * difficulty_level)
	fish_availability_multiplier = min(fish_availability_multiplier, 1.0 / config.min_fish_availability_multiplier)
	
	stage_config.fish_min_spawn_interval = base_fish_min_interval * fish_availability_multiplier
	stage_config.fish_max_spawn_interval = base_fish_max_interval * fish_availability_multiplier
	
	if fish_availability_multiplier >= (1.0 / config.min_fish_availability_multiplier):
		parameter_capped.emit("fish_availability", stage_config.fish_min_spawn_interval)
	
	# Apply enhanced nest frequency scaling (more nests to feed over time)
	stage_config.nests_enabled = true
	
	# Use both old and new nest frequency systems
	# Old system: decrease max skipped obstacles
	var nest_max_decrease = int(config.nest_interval_decrease * difficulty_level)
	var new_nest_max_old = base_nest_max_skipped - nest_max_decrease
	new_nest_max_old = max(new_nest_max_old, config.min_nest_interval)
	
	# New system: multiply by frequency increase rate (makes nests even more frequent)
	var nest_frequency_multiplier = 1.0 - (config.nest_frequency_increase_rate * difficulty_level * 0.5)
	nest_frequency_multiplier = max(nest_frequency_multiplier, 1.0 / config.max_nest_frequency_multiplier)
	
	# Apply both systems - use the more aggressive (lower) value
	var new_nest_max_combined = int(new_nest_max_old * nest_frequency_multiplier)
	new_nest_max_combined = max(new_nest_max_combined, config.min_nest_interval)
	
	stage_config.nest_min_skipped_obstacles = max(1, min(base_nest_min_skipped, new_nest_max_combined - 1))
	stage_config.nest_max_skipped_obstacles = new_nest_max_combined
	
	if new_nest_max_combined <= config.min_nest_interval:
		parameter_capped.emit("nest_frequency", new_nest_max_combined)
	
	# Auto-difficulty never completes - it's endless
	stage_config.completion_type = StageConfiguration.CompletionType.TIMER
	stage_config.completion_value = 999999.0  # Effectively infinite
	
	print("AutoDifficultySystem: Generated config for level ", difficulty_level,
		  " - Speed: ", stage_config.world_speed, 
		  ", Min Distance: ", stage_config.min_obstacle_distance,
		  ", Heights: M(", stage_config.mountain_max_height, ") S(", stage_config.stalactite_max_height, ")",
		  ", Weights: M(", stage_config.mountain_weight, ") S(", stage_config.stalactite_weight, ") I(", stage_config.floating_island_weight, ")",
		  ", Fish: ", stage_config.fish_min_spawn_interval, "-", stage_config.fish_max_spawn_interval,
		  ", Nests: ", stage_config.nest_min_skipped_obstacles, "-", stage_config.nest_max_skipped_obstacles)
	
	return stage_config

## Get current difficulty statistics for debug UI
func get_difficulty_stats() -> Dictionary:
	if not config:
		return {}
		
	return {
		"level": difficulty_level,
		"time_to_next": config.progression_interval - progression_timer,
		"speed_multiplier": min(1.0 + (config.speed_increase_rate * difficulty_level), config.max_speed_multiplier),
		"distance_multiplier": max(1.0 - (config.spawn_rate_increase * difficulty_level * 0.5), config.min_distance_multiplier),
		"mountain_height_multiplier": min(1.0 + (config.mountain_height_increase_rate * difficulty_level), config.max_mountain_height_multiplier),
		"stalactite_height_multiplier": min(1.0 + (config.stalactite_height_increase_rate * difficulty_level), config.max_stalactite_height_multiplier),
		"mountain_weight": min(base_mountain_weight * (1.0 + config.mountain_weight_increase_rate * difficulty_level), config.max_obstacle_weight),
		"stalactite_weight": min(base_stalactite_weight + (config.stalactite_weight_increase * difficulty_level), config.max_stalactite_weight),
		"island_weight": min(base_island_weight * (1.0 + config.island_weight_increase_rate * difficulty_level), config.max_obstacle_weight),
		"fish_availability_multiplier": min(1.0 + (config.fish_availability_decrease_rate * difficulty_level), 1.0 / config.min_fish_availability_multiplier),
		"nest_frequency_multiplier": max(1.0 - (config.nest_frequency_increase_rate * difficulty_level * 0.5), 1.0 / config.max_nest_frequency_multiplier),
		"nest_max_skipped": max(base_nest_max_skipped - int(config.nest_interval_decrease * difficulty_level), config.min_nest_interval)
	}

## Reset auto-difficulty (useful for testing)
func reset():
	print("AutoDifficultySystem: Reset to level 0")
	progression_timer = 0.0
	difficulty_level = 0

## Force increase difficulty level (useful for testing)
func force_increase_level():
	difficulty_level += 1
	print("AutoDifficultySystem: Forced increase to level ", difficulty_level)
	difficulty_increased.emit(difficulty_level)

