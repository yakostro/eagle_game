extends Node2D

class_name ObstacleSpawner

@export var mountain_scene: PackedScene  # Drag your Mountain.tscn here
@export var spawn_interval: float = 5.0  # Seconds between spawns
@export var spawn_interval_variance: float = 2.0  # Random variation in timing
@export var min_spawn_interval: float = 2.0  # Minimum time between spawns

var spawn_timer: Timer
var screen_size: Vector2

func _ready():
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("Obstacle spawner initialized. Screen size: ", screen_size)

func _on_spawn_timer_timeout():
	spawn_mountain()
	
	# Set random interval for next spawn
	var next_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
	next_interval = max(next_interval, min_spawn_interval)
	spawn_timer.wait_time = next_interval
	spawn_timer.start()

func spawn_mountain():
	if not mountain_scene:
		print("Error: No mountain scene assigned to spawner!")
		return
	
	# Instantiate mountain
	var mountain = mountain_scene.instantiate()
	get_tree().current_scene.add_child(mountain)
	
	# Let mountain handle its own setup
	mountain.setup_mountain(screen_size.x, screen_size.y)
	
	print("Spawned mountain using its own setup method")

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.2, min_spawn_interval)
	print("Difficulty increased - Spawn interval: ", spawn_interval)

# Method to manually spawn mountain (for testing)
func spawn_mountain_now():
	spawn_mountain()

