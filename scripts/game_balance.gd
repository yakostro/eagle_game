extends Node

# =============================================================================
# GAME BALANCE CONFIGURATION - THE LAST EAGLE
# =============================================================================
# This singleton centralizes all game balance parameters for easy tweaking
# Usage: Access via GameBalance.variable_name from any script
# =============================================================================

# =============================================================================
# EAGLE ENERGY SYSTEM
# =============================================================================

# Base energy loss per second
@export var eagle_energy_loss_per_second: float = 5.0

# Energy loss multiplier based on morale (when morale is low)
@export var energy_loss_morale_multiplier: float = 2.0

# Energy loss when hit by obstacles
@export var obstacle_hit_energy_loss: float = 15.0

# Energy loss when hit by enemy birds
@export var enemy_bird_hit_energy_loss: float = 20.0

# Eagle hit immunity duration (seconds)
@export var eagle_hit_immunity_duration: float = 2.0

# Eagle maximum energy
@export var eagle_max_energy: float = 100.0

# Eagle starting energy
@export var eagle_starting_energy: float = 100.0

# =============================================================================
# MORALE SYSTEM
# =============================================================================

# Morale loss when nest goes off screen without being fed
@export var morale_loss_unfed_nest: float = 10.0

# Morale gain when successfully feeding a chick
@export var morale_gain_fed_chick: float = 15.0

# Maximum morale value
@export var max_morale: float = 100.0

# Starting morale value
@export var starting_morale: float = 50.0

# =============================================================================
# FISH SYSTEM
# =============================================================================

# Energy value provided by eating fish
@export var fish_energy_value: float = 25.0

# Fish spawn timing
@export var fish_spawn_interval_min: float = 3.0
@export var fish_spawn_interval_max: float = 8.0

# Fish jump physics
@export var fish_jump_velocity_min: float = 300.0
@export var fish_jump_velocity_max: float = 500.0
@export var fish_jump_angle_min: float = 45.0  # degrees
@export var fish_jump_angle_max: float = 75.0  # degrees

# Fish gravity
@export var fish_gravity: float = 980.0

# Fish cleanup position (how far below screen before deletion)
@export var fish_cleanup_offset: float = 200.0

# =============================================================================
# WORLD MOVEMENT SYSTEM
# =============================================================================

# Base world/eagle speed (shared by all moving objects)
@export var world_speed: float = 200.0

# Speed increase over time (difficulty progression)
@export var speed_increase_per_minute: float = 20.0

# Maximum world speed
@export var max_world_speed: float = 400.0

# =============================================================================
# OBSTACLE SYSTEM
# =============================================================================

# Obstacle spawn timing
@export var obstacle_spawn_interval_min: float = 4.0
@export var obstacle_spawn_interval_max: float = 10.0

# Obstacle spawn position (distance from right edge of screen)
@export var obstacle_spawn_offset: float = 100.0

# Difficulty progression - reduces spawn intervals over time
@export var obstacle_difficulty_increase_rate: float = 0.1  # per minute

# MOUNTAIN OBSTACLES
@export var mountain_y_position_offset: float = 500.0  # Y position variance

# STALACTITE OBSTACLES  
@export var stalactite_minimum_height: float = 100.0

# FLOATING ISLAND OBSTACLES
@export var floating_island_min_top_offset: float = 500.0
@export var floating_island_min_bottom_offset: float = 300.0

# =============================================================================
# NEST SYSTEM
# =============================================================================

# Nest spawn frequency (spawn on every N obstacles)
@export var nest_spawn_every_n_obstacles: int = 3

# Nest spawn randomization (min/max range for spawn intervals)
@export var nest_spawn_interval_min: int = 2
@export var nest_spawn_interval_max: int = 5

# Nest difficulty progression (increases spawn intervals over time)
@export var nest_spawn_difficulty_increase: float = 0.5  # per minute

# =============================================================================
# ENEMY SYSTEM
# =============================================================================

# Enemy bird spawn timing
@export var enemy_bird_spawn_interval_min: float = 8.0
@export var enemy_bird_spawn_interval_max: float = 15.0

# Enemy bird movement parameters
@export var enemy_bird_acceleration: float = 150.0
@export var enemy_bird_max_speed: float = 250.0
@export var enemy_bird_direction_change_speed: float = 2.0  # radians per second

# Enemy difficulty progression
@export var enemy_spawn_difficulty_increase: float = 0.2  # per minute

# =============================================================================
# SCREEN AND WORLD BOUNDARIES
# =============================================================================

# Screen boundaries for cleanup and spawning
@export var screen_cleanup_offset: float = 100.0  # How far off screen before cleanup

# World height boundaries for eagle movement
@export var world_height_buffer: float = 200.0  # Extra space above/below screen

# =============================================================================
# DIFFICULTY PROGRESSION
# =============================================================================

# Game duration tracking for difficulty scaling
var game_time_elapsed: float = 0.0

# Difficulty multipliers that increase over time
var current_difficulty_multiplier: float = 1.0

# Rate at which overall difficulty increases
@export var global_difficulty_increase_rate: float = 0.1  # per minute

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _ready():
	# Set up the singleton
	print("GameBalance singleton initialized")

# Update difficulty over time
func _process(delta):
	game_time_elapsed += delta
	update_difficulty()

# Calculate current difficulty multiplier based on elapsed time
func update_difficulty():
	var minutes_elapsed = game_time_elapsed / 60.0
	current_difficulty_multiplier = 1.0 + (minutes_elapsed * global_difficulty_increase_rate)

# Get current world speed adjusted for difficulty
func get_current_world_speed() -> float:
	var minutes_elapsed = game_time_elapsed / 60.0
	var speed = world_speed + (minutes_elapsed * speed_increase_per_minute)
	return min(speed, max_world_speed)

# Get current obstacle spawn interval adjusted for difficulty
func get_current_obstacle_spawn_interval() -> float:
	var minutes_elapsed = game_time_elapsed / 60.0
	var reduction = minutes_elapsed * obstacle_difficulty_increase_rate
	var min_interval = max(obstacle_spawn_interval_min - reduction, 1.0)
	var max_interval = max(obstacle_spawn_interval_max - reduction, 2.0)
	return randf_range(min_interval, max_interval)

# Get current enemy spawn interval adjusted for difficulty
func get_current_enemy_spawn_interval() -> float:
	var minutes_elapsed = game_time_elapsed / 60.0
	var reduction = minutes_elapsed * enemy_spawn_difficulty_increase
	var min_interval = max(enemy_bird_spawn_interval_min - reduction, 3.0)
	var max_interval = max(enemy_bird_spawn_interval_max - reduction, 6.0)
	return randf_range(min_interval, max_interval)

# Get current nest spawn interval adjusted for difficulty
func get_current_nest_spawn_interval() -> int:
	var minutes_elapsed = game_time_elapsed / 60.0
	var increase = int(minutes_elapsed * nest_spawn_difficulty_increase)
	var min_spawn = nest_spawn_interval_min + increase
	var max_spawn = nest_spawn_interval_max + increase
	return randi_range(min_spawn, max_spawn)

# Calculate energy loss per second based on current morale
func get_energy_loss_rate(current_morale: float) -> float:
	if current_morale <= 0:
		return eagle_energy_loss_per_second * energy_loss_morale_multiplier
	else:
		# Linear scaling based on morale percentage
		var morale_percentage = current_morale / max_morale
		var multiplier = lerp(energy_loss_morale_multiplier, 1.0, morale_percentage)
		return eagle_energy_loss_per_second * multiplier

# Get random fish jump parameters
func get_fish_jump_parameters() -> Dictionary:
	return {
		"velocity": randf_range(fish_jump_velocity_min, fish_jump_velocity_max),
		"angle": deg_to_rad(randf_range(fish_jump_angle_min, fish_jump_angle_max))
	}

# Reset game time (useful for restarting)
func reset_game_time():
	game_time_elapsed = 0.0
	current_difficulty_multiplier = 1.0
