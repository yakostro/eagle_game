extends Node2D

class_name ObstacleSpawner

@export var mountain_scene: PackedScene  # Drag your Mountain.tscn here
@export var nest_scene: PackedScene  # Drag your Nest.tscn here
@export var spawn_interval: float = 5.0  # Seconds between spawns
@export var spawn_interval_variance: float = 2.0  # Random variation in timing
@export var min_spawn_interval: float = 2.0  # Minimum time between spawns
@export var nest_spawn_frequency: int = 1  # Spawn nest every N obstacles

var spawn_timer: Timer
var screen_size: Vector2
var obstacle_count: int = 0  # Counter to track spawned obstacles for nest spawning

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
	
	# Increment obstacle counter
	obstacle_count += 1
	
	# Check if we should spawn a nest on this obstacle
	if obstacle_count % nest_spawn_frequency == 0:
		spawn_nest_on_obstacle(mountain)
	
	print("Spawned mountain using its own setup method. Total obstacles: ", obstacle_count)

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.2, min_spawn_interval)
	print("Difficulty increased - Spawn interval: ", spawn_interval)

func spawn_nest_on_obstacle(obstacle: Node2D):
	if not nest_scene:
		print("Error: No nest scene assigned to spawner!")
		return
	
	# Instantiate nest
	var nest = nest_scene.instantiate()
	
	# Add nest as child of obstacle so it moves with the mountain
	obstacle.add_child(nest)
	
	# Position nest using the placeholder if it exists
	var nest_placeholder = obstacle.get_node_or_null("NestPlaceholder")
	if nest_placeholder:
		# Use the placeholder's position
		nest.position = nest_placeholder.position
		print("Spawned nest using placeholder at position: ", nest.position)
	else:
		# Fallback to default positioning
		nest.position = Vector2(0, 20)
		print("Warning: No NestPlaceholder found, using default position")

# Method to manually spawn mountain (for testing)
func spawn_mountain_now():
	spawn_mountain()

