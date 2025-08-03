class_name NestSpawner
extends Node

@export var nest_scene: PackedScene  # Drag your Nest.tscn here
@export var eagle_reference: Eagle  # Reference to the eagle for signal connections

# Precise nest spawning system
@export var min_skipped_obstacles: int = 0  # Minimum obstacles to skip before spawning nest
@export var max_skipped_obstacles: int = 0  # Maximum obstacles to skip before spawning nest

# Nest difficulty progression
@export var nest_difficulty_increase_interval: int = 10  # Increase difficulty every N obstacles
@export var nest_difficulty_increase_amount: int = 1     # How much to increase min/max by
@export var max_nest_difficulty: int = 8                # Maximum value for max_skipped_obstacles

# Nest spawning system variables
var obstacles_since_last_nest: int = 0  # Track obstacles spawned since last nest
var next_nest_spawn_target: int = 0  # How many obstacles to skip before next nest

# Difficulty progression tracking
var initial_min_skipped: int = 0  # Store initial values
var initial_max_skipped: int = 0
var last_difficulty_increase_at: int = 0  # Track when we last increased difficulty
var total_obstacles_processed: int = 0  # Total obstacles we've seen

func _ready():
	# Store initial nest difficulty values
	initial_min_skipped = min_skipped_obstacles
	initial_max_skipped = max_skipped_obstacles
	
	# Initialize nest spawn target
	_set_next_nest_spawn_target()
	
	print("🏠 Nest spawner initialized")
	print("   Initial nest difficulty: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
	print("   First nest will spawn after ", next_nest_spawn_target, " obstacles")
	print("   Difficulty will increase every ", nest_difficulty_increase_interval, " obstacles")

func on_obstacle_spawned(obstacle: BaseObstacle):
	"""Called when an obstacle is spawned - decide if it should get a nest"""
	if not obstacle:
		print("Warning: null obstacle passed to nest spawner")
		return
	
	# Increment counters
	total_obstacles_processed += 1
	obstacles_since_last_nest += 1
	
	# Check if we should increase nest difficulty
	if total_obstacles_processed - last_difficulty_increase_at >= nest_difficulty_increase_interval:
		_increase_nest_difficulty()
	
	# Check if this obstacle should get a nest
	if _should_spawn_nest_on_obstacle(obstacle):
		spawn_nest_on_obstacle(obstacle)
		# Reset counter and set new random target
		obstacles_since_last_nest = 0
		_set_next_nest_spawn_target()
	
	print("🏠 Nest spawner processed ", obstacle.get_obstacle_type(), " | Total: ", total_obstacles_processed, " | Since last nest: ", obstacles_since_last_nest, "/", next_nest_spawn_target)

func _should_spawn_nest_on_obstacle(obstacle: BaseObstacle) -> bool:
	"""Determine if this obstacle should get a nest"""
	# Check if we've reached the target number of skipped obstacles
	if obstacles_since_last_nest < next_nest_spawn_target:
		return false
	
	# Check if this obstacle type can carry nests
	if not obstacle.can_carry_nest:
		print("   ❌ ", obstacle.get_obstacle_type(), " cannot carry nests")
		return false
	
	# Check if obstacle actually has a nest placeholder
	if not obstacle.has_nest_placeholder():
		print("   ❌ ", obstacle.get_obstacle_type(), " has no NestPlaceholder node")
		return false
	
	print("   ✅ ", obstacle.get_obstacle_type(), " will get a nest!")
	return true

func spawn_nest_on_obstacle(obstacle: BaseObstacle):
	"""Spawn a nest on the given obstacle"""
	if not nest_scene:
		print("Error: No nest scene assigned to nest spawner!")
		return
	
	if not eagle_reference:
		print("Error: No eagle reference assigned to nest spawner for signal connections!")
		return
	
	# Instantiate nest
	var nest = nest_scene.instantiate()
	
	# Add nest as child of obstacle so it moves with the obstacle
	obstacle.add_child(nest)
	
	# Position nest using the placeholder
	var nest_placeholder = obstacle.get_nest_placeholder()
	if nest_placeholder:
		# Use the placeholder's position
		nest.position = nest_placeholder.position
		print("   🏠 Spawned nest using placeholder at position: ", nest.position)
	else:
		# This shouldn't happen due to has_nest_placeholder() check, but just in case
		nest.position = Vector2(0, 20)
		print("   🏠 Warning: No NestPlaceholder found, using default position")
	
	# Connect nest signals to eagle's morale methods
	nest.nest_fed.connect(eagle_reference.on_nest_fed)
	nest.nest_missed.connect(eagle_reference.on_nest_missed)
	print("   🔗 Connected nest signals to eagle morale system")

func _increase_nest_difficulty():
	"""Increase nest spawning difficulty over time"""
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
	last_difficulty_increase_at = total_obstacles_processed
	
	print("🔥 NEST SPAWN INTERVALS CHANGED! 🔥")
	print("   Obstacle count: ", total_obstacles_processed)
	print("   Previous: min=", min_skipped_obstacles - nest_difficulty_increase_amount, " max=", max_skipped_obstacles - nest_difficulty_increase_amount)
	print("   New values: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
	print("   Next change at obstacle: ", total_obstacles_processed + nest_difficulty_increase_interval)
	
	# If we currently don't have a nest target set, update it with new difficulty
	if obstacles_since_last_nest == 0:
		_set_next_nest_spawn_target()

func _set_next_nest_spawn_target():
	"""Set random nest spawn target within current difficulty range"""
	next_nest_spawn_target = randi_range(min_skipped_obstacles, max_skipped_obstacles)
	print("   🎯 Next nest will spawn after skipping ", next_nest_spawn_target, " obstacles")
