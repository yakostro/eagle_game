extends Node2D

class_name ObstacleSpawner
@export var mountain_scene: PackedScene  # Drag your Mountain.tscn here
@export var nest_scene: PackedScene  # Drag your Nest.tscn here
@export var eagle_reference: Eagle  # Reference to the eagle for signal connections

# mountain balance
@export var spawn_interval: float = 5.0  # Seconds between spawns
@export var spawn_interval_variance: float = 2.0  # Random variation in timing
@export var min_spawn_interval: float = 1.0  # Minimum time between spawns

# Precise nest spawning system
@export var min_skipped_obstacles: int = 0  # Minimum obstacles to skip before spawning nest
@export var max_skipped_obstacles: int = 0  # Maximum obstacles to skip before spawning nest

# Nest difficulty progression
@export var nest_difficulty_increase_interval: int = 10  # Increase difficulty every N obstacles
@export var nest_difficulty_increase_amount: int = 1     # How much to increase min/max by
@export var max_nest_difficulty: int = 8                # Maximum value for max_skipped_obstacles

var spawn_timer: Timer
var screen_size: Vector2
var obstacle_count: int = 0  # Counter to track spawned obstacles for difficulty progression

# Nest spawning system variables
var obstacles_since_last_nest: int = 0  # Track obstacles spawned since last nest
var next_nest_spawn_target: int = 0  # How many obstacles to skip before next nest

# Difficulty progression tracking
var initial_min_skipped: int = 0  # Store initial values
var initial_max_skipped: int = 0
var last_difficulty_increase_at: int = 0  # Track when we last increased difficulty

func _ready():
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Store initial nest difficulty values
	initial_min_skipped = min_skipped_obstacles
	initial_max_skipped = max_skipped_obstacles
	
	# Initialize nest spawn target
	_set_next_nest_spawn_target()
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("Obstacle spawner initialized. Screen size: ", screen_size)
	print("🎯 Initial nest difficulty: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
	print("   First nest will spawn after ", next_nest_spawn_target, " obstacles")
	print("   Difficulty will increase every ", nest_difficulty_increase_interval, " obstacles")

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
	obstacles_since_last_nest += 1
	
	# Check if we should increase nest difficulty
	if obstacle_count - last_difficulty_increase_at >= nest_difficulty_increase_interval:
		_increase_nest_difficulty()
	
	# Check if we should spawn a nest using new precise system
	if obstacles_since_last_nest >= next_nest_spawn_target:
		spawn_nest_on_obstacle(mountain)
		# Reset counter and set new random target
		obstacles_since_last_nest = 0
		_set_next_nest_spawn_target()
	
	print("Spawned mountain using its own setup method. Total obstacles: ", obstacle_count, " | Obstacles since last nest: ", obstacles_since_last_nest, "/", next_nest_spawn_target)

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.2, min_spawn_interval)
	print("Difficulty increased - Spawn interval: ", spawn_interval)

# Method to increase nest spawning difficulty over time
func _increase_nest_difficulty():
	# Don't increase if we've reached maximum difficulty
	if max_skipped_obstacles >= max_nest_difficulty:
		print("⚠️  MAXIMUM NEST DIFFICULTY REACHED! No further increases. Current: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
		return
	
	# Increase both min and max by the specified amount
	min_skipped_obstacles += nest_difficulty_increase_amount
	max_skipped_obstacles += nest_difficulty_increase_amount
	
	# Ensure max doesn't exceed the limit
	max_skipped_obstacles = min(max_skipped_obstacles, max_nest_difficulty)
	
	# Ensure min doesn't exceed max
	min_skipped_obstacles = min(min_skipped_obstacles, max_skipped_obstacles)
	
	# Update when we last increased difficulty
	last_difficulty_increase_at = obstacle_count
	
	print("🔥 NEST SPAWN INTERVALS CHANGED! 🔥")
	print("   Obstacle count: ", obstacle_count)
	print("   Previous: min=", min_skipped_obstacles - nest_difficulty_increase_amount, " max=", max_skipped_obstacles - nest_difficulty_increase_amount)
	print("   New values: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
	print("   Next change at obstacle: ", obstacle_count + nest_difficulty_increase_interval)
	
	# If we currently don't have a nest target set, update it with new difficulty
	if obstacles_since_last_nest == 0:
		_set_next_nest_spawn_target()

func spawn_nest_on_obstacle(obstacle: Node2D):
	if not nest_scene:
		print("Error: No nest scene assigned to spawner!")
		return
	
	if not eagle_reference:
		print("Error: No eagle reference assigned to spawner for signal connections!")
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
	
	# Connect nest signals to eagle's morale methods
	nest.nest_fed.connect(eagle_reference.on_nest_fed)
	nest.nest_missed.connect(eagle_reference.on_nest_missed)
	print("Connected nest signals to eagle morale system")

# Method to manually spawn mountain (for testing)
func spawn_mountain_now():
	spawn_mountain()

# Helper function to set random nest spawn target
func _set_next_nest_spawn_target():
	next_nest_spawn_target = randi_range(min_skipped_obstacles, max_skipped_obstacles)
	print("Next nest will spawn after skipping ", next_nest_spawn_target, " obstacles")

