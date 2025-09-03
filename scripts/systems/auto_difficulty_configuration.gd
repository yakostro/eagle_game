class_name AutoDifficultyConfiguration
extends Resource

## Auto-Difficulty Configuration Resource
## 
## This resource contains all the balance parameters for the auto-difficulty system.
## Stored as .tres files for easy tweaking without code changes.

# Progression timing
@export var progression_interval: float = 30.0  # Every 30 seconds difficulty increases

# Speed progression
@export var speed_increase_rate: float = 0.05  # 5% increase per interval
@export var max_speed_multiplier: float = 2.0  # Cap at 2x original speed

# Spawn rate progression (affects obstacle distances)
@export var spawn_rate_increase: float = 0.1   # 10% faster spawning (shorter distances)
@export var min_distance_multiplier: float = 0.5  # Never closer than 50% of original distance

# Obstacle weight progression
@export var stalactite_weight_increase: int = 1  # Add 1 weight per interval
@export var max_stalactite_weight: int = 20     # Cap stalactite frequency

# Fish spawn progression
@export var fish_spawn_rate_increase: float = 0.1  # 10% faster fish spawning
@export var min_fish_interval_multiplier: float = 0.3  # Never faster than 30% of original

# Nest progression (make nests more frequent)
@export var nest_interval_decrease: int = 1      # Decrease max skipped obstacles
@export var min_nest_interval: int = 2           # Minimum obstacles between nests

# Configuration validation
func validate() -> bool:
	if progression_interval <= 0:
		push_error("AutoDifficultyConfiguration: progression_interval must be > 0")
		return false
	
	if speed_increase_rate <= 0 or speed_increase_rate > 1.0:
		push_error("AutoDifficultyConfiguration: speed_increase_rate should be between 0 and 1")
		return false
		
	if max_speed_multiplier <= 1.0:
		push_error("AutoDifficultyConfiguration: max_speed_multiplier should be > 1.0")
		return false
	
	if spawn_rate_increase <= 0 or spawn_rate_increase > 1.0:
		push_error("AutoDifficultyConfiguration: spawn_rate_increase should be between 0 and 1")
		return false
		
	if min_distance_multiplier <= 0 or min_distance_multiplier > 1.0:
		push_error("AutoDifficultyConfiguration: min_distance_multiplier should be between 0 and 1")
		return false
	
	if stalactite_weight_increase < 0:
		push_error("AutoDifficultyConfiguration: stalactite_weight_increase should be >= 0")
		return false
		
	if max_stalactite_weight <= 0:
		push_error("AutoDifficultyConfiguration: max_stalactite_weight should be > 0")
		return false
	
	if fish_spawn_rate_increase < 0 or fish_spawn_rate_increase > 1.0:
		push_error("AutoDifficultyConfiguration: fish_spawn_rate_increase should be between 0 and 1")
		return false
		
	if min_fish_interval_multiplier <= 0 or min_fish_interval_multiplier > 1.0:
		push_error("AutoDifficultyConfiguration: min_fish_interval_multiplier should be between 0 and 1")
		return false
	
	if nest_interval_decrease < 0:
		push_error("AutoDifficultyConfiguration: nest_interval_decrease should be >= 0")
		return false
		
	if min_nest_interval <= 0:
		push_error("AutoDifficultyConfiguration: min_nest_interval should be > 0")
		return false
	
	return true

# Get a summary of the configuration for debug display
func get_summary() -> String:
	return "Auto-Difficulty Config: %ds intervals, +%.1f%% speed/interval (max %.1fx), +%.1f%% spawn rate/interval (min %.1fx distance)" % [
		progression_interval, 
		speed_increase_rate * 100, 
		max_speed_multiplier,
		spawn_rate_increase * 100,
		min_distance_multiplier
	]
