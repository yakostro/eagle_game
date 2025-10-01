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
	
	# Apply obstacle weight progression
	stage_config.mountain_weight = 10  # Keep mountains constant
	stage_config.floating_island_weight = 5  # Keep islands constant
	
	# Increase stalactite weight over time
	var stalactite_weight = base_stalactite_weight + (config.stalactite_weight_increase * difficulty_level)
	stalactite_weight = min(stalactite_weight, config.max_stalactite_weight)
	stage_config.stalactite_weight = stalactite_weight
	
	if stalactite_weight >= config.max_stalactite_weight:
		parameter_capped.emit("stalactite_weight", stalactite_weight)
	
	# Apply distance scaling (shorter distances = faster spawning)
	var distance_multiplier = 1.0 - (config.spawn_rate_increase * difficulty_level * 0.5)  # Slower progression
	distance_multiplier = max(distance_multiplier, config.min_distance_multiplier)
	
	stage_config.min_obstacle_distance = base_min_obstacle_distance * distance_multiplier
	stage_config.max_obstacle_distance = base_max_obstacle_distance * distance_multiplier
	
	if distance_multiplier <= config.min_distance_multiplier:
		parameter_capped.emit("obstacle_distance", stage_config.min_obstacle_distance)
	
	# Keep same obstacle repeat chance
	stage_config.same_obstacle_repeat_chance = 0.1
	
	# Apply fish spawn scaling
	stage_config.fish_enabled = true
	var fish_multiplier = 1.0 - (config.fish_spawn_rate_increase * difficulty_level * 0.3)  # Slower progression
	fish_multiplier = max(fish_multiplier, config.min_fish_interval_multiplier)
	
	stage_config.fish_min_spawn_interval = base_fish_min_interval * fish_multiplier
	stage_config.fish_max_spawn_interval = base_fish_max_interval * fish_multiplier
	
	if fish_multiplier <= config.min_fish_interval_multiplier:
		parameter_capped.emit("fish_intervals", stage_config.fish_min_spawn_interval)
	
	# Apply nest frequency scaling
	stage_config.nests_enabled = true
	var nest_max_decrease = int(config.nest_interval_decrease * difficulty_level)
	var new_nest_max = base_nest_max_skipped - nest_max_decrease
	new_nest_max = max(new_nest_max, config.min_nest_interval)
	
	stage_config.nest_min_skipped_obstacles = min(base_nest_min_skipped, new_nest_max - 1)
	stage_config.nest_max_skipped_obstacles = new_nest_max
	
	if new_nest_max <= config.min_nest_interval:
		parameter_capped.emit("nest_intervals", new_nest_max)
	
	# Auto-difficulty never completes - it's endless
	stage_config.completion_type = StageConfiguration.CompletionType.TIMER
	stage_config.completion_value = 999999.0  # Effectively infinite
	
	print("AutoDifficultySystem: Generated config for level ", difficulty_level,
		  " - Speed: ", stage_config.world_speed, 
		  ", Min Distance: ", stage_config.min_obstacle_distance,
		  ", Stalactite Weight: ", stage_config.stalactite_weight)
	
	return stage_config

## Get current difficulty statistics for debug UI
func get_difficulty_stats() -> Dictionary:
	if not config:
		return {}
		
	return {
		"level": difficulty_level,
		"time_to_next": config.progression_interval - progression_timer,
		"speed_multiplier": 1.0 + (config.speed_increase_rate * difficulty_level),
		"distance_multiplier": max(1.0 - (config.spawn_rate_increase * difficulty_level * 0.5), config.min_distance_multiplier),
		"stalactite_weight": min(base_stalactite_weight + (config.stalactite_weight_increase * difficulty_level), config.max_stalactite_weight),
		"fish_multiplier": max(1.0 - (config.fish_spawn_rate_increase * difficulty_level * 0.3), config.min_fish_interval_multiplier),
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

