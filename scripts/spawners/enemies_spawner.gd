class_name EnemiesSpawner
extends Node

# Enemy bird spawning configuration
@export var enemy_bird_scene: PackedScene  # Drag the enemy_bird.tscn here in the editor
@export var spawn_distance_from_screen: float = 100.0  # How far right of screen to spawn

# Spawn timing and difficulty now controlled by GameBalance singleton
# @export var spawn_interval_min: float = 10.0  # Now using GameBalance parameters
# @export var spawn_interval_max: float = 15.0  # Now using GameBalance parameters
# @export var difficulty_increase_interval: float = 30.0  # Now automatic via GameBalance
# @export var difficulty_spawn_rate_multiplier: float = 0.9  # Now handled by GameBalance
# @export var min_spawn_interval: float = 5.0  # Now using GameBalance parameters

# Internal state
var spawn_timer: float = 0.0  # Timer until next spawn
var next_spawn_time: float = 0.0  # When to spawn next enemy
# Difficulty progression now handled by GameBalance singleton

# References
var game_area: Node  # Parent node where enemies will be spawned

func _ready():
	# Find the game area (parent node where enemies should be spawned)
	game_area = get_tree().get_first_node_in_group("game_area")
	if not game_area:
		# If no game_area group found, use the current scene root
		game_area = get_tree().current_scene
		print("Warning: No 'game_area' group found, using scene root for enemy spawning")
	
	# Set initial spawn time
	reset_spawn_timer()
	
	print("Enemies spawner initialized. First spawn in: ", next_spawn_time, " seconds")

func _process(delta):
	# Update spawn timer
	spawn_timer += delta
	
	# Check if it's time to spawn an enemy
	if spawn_timer >= next_spawn_time:
		spawn_enemy_bird()
		reset_spawn_timer()

func spawn_enemy_bird():
	"""Spawn an enemy bird on the right side of the screen"""
	if not enemy_bird_scene:
		print("Error: No enemy bird scene assigned to spawner!")
		return
	
	# Find the eagle to get its Y position
	var eagle = get_tree().get_first_node_in_group("eagle")
	if not eagle:
		print("Warning: Could not find eagle for bird spawning!")
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
	
	print("Enemy bird spawned at position: ", enemy_bird.global_position, " (eagle Y: ", eagle.global_position.y, ") | Game time: ", GameBalance.game_time_elapsed)

func reset_spawn_timer():
	"""Reset the spawn timer with a random interval using GameBalance parameters"""
	spawn_timer = 0.0
	next_spawn_time = GameBalance.get_current_enemy_spawn_interval()
	
	print("Next enemy bird spawn in: ", next_spawn_time, " seconds")

# Difficulty progression is now handled automatically by the GameBalance singleton
# Enemy spawn intervals adjust dynamically based on game time
