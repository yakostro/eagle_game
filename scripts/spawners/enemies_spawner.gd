class_name EnemiesSpawner
extends Node

# Enemy bird spawning configuration
@export var enemy_bird_scene: PackedScene  # Drag the enemy_bird.tscn here in the editor
@export var spawn_interval_min: float = 70.0  # Minimum time between spawns
@export var spawn_interval_max: float = 100.0  # Maximum time between spawns
@export var spawn_distance_from_screen: float = 100.0  # How far right of screen to spawn

# Difficulty progression variables
@export var difficulty_increase_interval: float = 30.0  # Increase difficulty every 30 seconds
@export var difficulty_spawn_rate_multiplier: float = 0.9  # Multiply spawn intervals by this each difficulty increase
@export var min_spawn_interval: float = 1.0  # Don't go below this spawn interval

# Internal state
var spawn_timer: float = 0.0  # Timer until next spawn
var next_spawn_time: float = 0.0  # When to spawn next enemy
var difficulty_timer: float = 0.0  # Timer for difficulty progression
var current_difficulty_level: int = 0  # Current difficulty level

# References
var game_area: Node  # Parent node where enemies will be spawned

func _ready():
	# Find the game area (parent node where enemies should be spawned)
	game_area = get_tree().get_first_node_in_group("game_area")
	if not game_area:
		# If no game_area group found, use the current scene root
		game_area = get_tree().current_scene
	
	# Set initial spawn time
	reset_spawn_timer()

func _process(delta):
	# Update timers
	spawn_timer += delta
	difficulty_timer += delta
	
	# Check for difficulty progression
	if difficulty_timer >= difficulty_increase_interval:
		increase_difficulty()
		difficulty_timer = 0.0
	
	# Check if it's time to spawn an enemy
	if spawn_timer >= next_spawn_time:
		spawn_enemy_bird()
		reset_spawn_timer()

func spawn_enemy_bird():
	"""Spawn an enemy bird on the right side of the screen"""
	if not enemy_bird_scene:
		return
	
	# Find the eagle to get its Y position
	var eagle = get_tree().get_first_node_in_group("eagle")
	if not eagle:
		return
	
	# Get screen bounds
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var camera = viewport.get_camera_2d()
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	# Calculate spawn position (right side of screen + offset)
	var spawn_x = camera_pos.x + screen_size.x / 2 + spawn_distance_from_screen
	var spawn_y = eagle.global_position.y  # Spawn at eagle's current Y position
	
	# Create enemy bird instance
	var enemy_bird = enemy_bird_scene.instantiate()
	enemy_bird.global_position = Vector2(spawn_x, spawn_y)
	
	# Add to the game area
	game_area.add_child(enemy_bird)
	
	print("Enemy bird spawned at position: ", enemy_bird.global_position, " (eagle Y: ", eagle.global_position.y, ") | Difficulty level: ", current_difficulty_level)

func reset_spawn_timer():
	"""Reset the spawn timer with a random interval"""
	spawn_timer = 0.0
	next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)
	
	print("Next enemy bird spawn in: ", next_spawn_time, " seconds")

func increase_difficulty():
	"""Increase the difficulty by spawning enemies more frequently"""
	current_difficulty_level += 1
	
	# Reduce spawn intervals (make enemies spawn more frequently)
	spawn_interval_min *= difficulty_spawn_rate_multiplier
	spawn_interval_max *= difficulty_spawn_rate_multiplier
	
	# Don't let intervals go below minimum
	spawn_interval_min = max(spawn_interval_min, min_spawn_interval)
	spawn_interval_max = max(spawn_interval_max, min_spawn_interval)
	
	print("Difficulty increased! Level: ", current_difficulty_level)
	print("New spawn intervals: ", spawn_interval_min, " - ", spawn_interval_max, " seconds")
	
	# Reset spawn timer with new intervals
	reset_spawn_timer()

func get_difficulty_level() -> int:
	"""Get the current difficulty level"""
	return current_difficulty_level
