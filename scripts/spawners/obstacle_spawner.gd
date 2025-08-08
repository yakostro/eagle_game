extends Node2D

class_name ObstacleSpawner

# Obstacle scenes with spawn weights
@export var mountain_scene: PackedScene  # Drag your Mountain.tscn here
@export var stalactite_scene: PackedScene  # Drag your Stalactite.tscn here  
@export var floating_island_scene: PackedScene  # Drag your FloatingIsland.tscn here

# Spawn weights for obstacle types (higher = more likely to spawn)
@export var mountain_weight: int = 2 #2
@export var stalactite_weight: int = 10 #2
@export var floating_island_weight: int = 5 #5

# Obstacle spawning balance
@export var spawn_interval: float = 5.0  # Seconds between spawns
@export var spawn_interval_variance: float = 1.0  # Random variation in timing
@export var min_spawn_interval: float = 3.0  # Minimum time between spawns

# Movement speed (should match eagle/world speed as per GDD)
@export var obstacle_movement_speed: float = 300.0

# Reference to nest spawner for coordination
@export var nest_spawner: NestSpawner

var spawn_timer: Timer
var screen_size: Vector2
var obstacle_count: int = 0  # Counter to track spawned obstacles for difficulty progression

# Signal emitted when an obstacle is spawned
signal obstacle_spawned(obstacle: BaseObstacle)

# Obstacle type data for weighted random selection
var obstacle_types: Array[Dictionary] = []

func _ready():
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Initialize obstacle types array
	_setup_obstacle_types()
	
	# Connect to nest spawner if available
	if nest_spawner:
		obstacle_spawned.connect(nest_spawner.on_obstacle_spawned)
		print("🔗 Connected to NestSpawner")
	else:
		print("⚠️  No NestSpawner connected - nests will not spawn")
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("🏔️  Obstacle spawner initialized. Screen size: ", screen_size)
	print("   Available obstacle types: ", obstacle_types.size())
	for obstacle_type in obstacle_types:
		print("   - ", obstacle_type.name, " (weight: ", obstacle_type.weight, ")")
	print("   Spawn interval: ", spawn_interval, "±", spawn_interval_variance, " seconds")

func _setup_obstacle_types():
	"""Initialize the obstacle types array with scenes and weights"""
	obstacle_types.clear()
	
	if mountain_scene:
		obstacle_types.append({"name": "Mountain", "scene": mountain_scene, "weight": mountain_weight})
	
	if stalactite_scene:
		obstacle_types.append({"name": "Stalactite", "scene": stalactite_scene, "weight": stalactite_weight})
	
	if floating_island_scene:
		obstacle_types.append({"name": "FloatingIsland", "scene": floating_island_scene, "weight": floating_island_weight})
	
	if obstacle_types.is_empty():
		push_error("No obstacle scenes assigned to ObstacleSpawner!")

func _on_spawn_timer_timeout():
	spawn_random_obstacle()
	
	# Set random interval for next spawn
	var next_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
	next_interval = max(next_interval, min_spawn_interval)
	spawn_timer.wait_time = next_interval
	spawn_timer.start()

func spawn_random_obstacle():
	"""Spawn a random obstacle based on weights"""
	if obstacle_types.is_empty():
		print("Error: No obstacle types available!")
		return
	
	# Select random obstacle type using weighted selection
	var selected_type = _get_weighted_random_obstacle_type()
	if not selected_type:
		print("Error: Failed to select obstacle type!")
		return
	
	# Instantiate the obstacle
	var obstacle_scene = selected_type.scene
	var obstacle = obstacle_scene.instantiate()
	get_tree().current_scene.add_child(obstacle)
	
	# Set up the obstacle with shared movement speed
	obstacle.set_movement_speed(obstacle_movement_speed)
	obstacle.setup_obstacle(screen_size.x, screen_size.y)
	
	# Increment obstacle counter
	obstacle_count += 1
	
	# Emit signal for nest spawner to handle
	obstacle_spawned.emit(obstacle)
	
	print("🏔️  Spawned ", selected_type.name, " | Total obstacles: ", obstacle_count)

func _get_weighted_random_obstacle_type() -> Dictionary:
	"""Select a random obstacle type based on weights"""
	# Calculate total weight
	var total_weight = 0
	for obstacle_type in obstacle_types:
		total_weight += obstacle_type.weight
	
	if total_weight <= 0:
		return {}
	
	# Generate random number and find corresponding type
	var random_value = randi_range(1, total_weight)
	var current_weight = 0
	
	for obstacle_type in obstacle_types:
		current_weight += obstacle_type.weight
		if random_value <= current_weight:
			return obstacle_type
	
	# Fallback to first type
	return obstacle_types[0]

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.2, min_spawn_interval)
	print("🔥 Difficulty increased - Spawn interval: ", spawn_interval)

# Method to manually spawn obstacle (for testing)
func spawn_obstacle_now():
	spawn_random_obstacle()

