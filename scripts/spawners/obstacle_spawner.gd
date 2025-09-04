extends Node2D

class_name ObstacleSpawner

## Spawns obstacles (mountains, stalactites, floating islands) with weighted random selection
## Difficulty progression is now managed by the StageManager system

# Obstacle scenes with spawn weights
@export var mountain_scenes: Array[PackedScene] = []  # Array of mountain variants (A, B, C)
@export var stalactite_scene: PackedScene  # Drag your Stalactite.tscn here  
@export var floating_island_scene: PackedScene  # Drag your FloatingIsland.tscn here

# Spawn weights for obstacle types (now controlled by StageManager)
var mountain_weight: int = 10
var stalactite_weight: int = 0  # 0 = disabled
var floating_island_weight: int = 5

# Movement speed (now controlled by StageManager)
var obstacle_movement_speed: float = 300.0

# Distance parameters from current stage
var min_obstacle_distance: float = 400.0
var max_obstacle_distance: float = 800.0
var same_obstacle_repeat_chance: float = 0.1

# Current stage configuration reference
var current_stage_config: StageConfiguration

# Reference to nest spawner for coordination
@export var nest_spawner: NestSpawner

var screen_size: Vector2
var obstacle_count: int = 0  # Counter to track spawned obstacles
var last_obstacle_x: float = 0.0  # Track X position of last spawned obstacle

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

	print("🏔️  Obstacle spawner initialized. Screen size: ", screen_size)
	print("   Available obstacle types: ", obstacle_types.size())
	for obstacle_type in obstacle_types:
		print("   - ", obstacle_type["name"], " (weight: ", obstacle_type["weight"], ")")
	print("   Distance range: ", min_obstacle_distance, "-", max_obstacle_distance)

	# Connect to StageManager for stage-based configuration
	_connect_to_stage_manager()

func _process(_delta):
	# Check if we need to spawn a new obstacle based on distance
	_check_distance_based_spawning()

	# Debug key to manually spawn obstacle (Enter key for testing)
	if Input.is_action_just_pressed("ui_accept"):
		spawn_obstacle_now()
		print("🎮 Manual obstacle spawn triggered!")

func _setup_obstacle_types():
	"""Initialize the obstacle types array with scenes and weights"""
	obstacle_types.clear()
	
	# Add mountain variants - each variant gets its own entry with the mountain weight
	if not mountain_scenes.is_empty():
		for i in range(mountain_scenes.size()):
			var mountain_scene = mountain_scenes[i]
			if mountain_scene:
				var variant_name = "Mountain" + char(65 + i)  # Mountain A, B, C...
				obstacle_types.append({"name": variant_name, "scene": mountain_scene, "weight": mountain_weight})
	
	if stalactite_scene:
		obstacle_types.append({"name": "Stalactite", "scene": stalactite_scene, "weight": stalactite_weight})
	
	if floating_island_scene:
		obstacle_types.append({"name": "FloatingIsland", "scene": floating_island_scene, "weight": floating_island_weight})
	
	if obstacle_types.is_empty():
		push_error("No obstacle scenes assigned to ObstacleSpawner!")

func _check_distance_based_spawning():
	"""Check if we need to spawn a new obstacle based on distance from last obstacle"""
	if obstacle_types.is_empty():
		return

	# If no obstacles spawned yet, spawn first one at initial distance from screen
	if last_obstacle_x == 0.0:
		last_obstacle_x = screen_size.x + randf_range(min_obstacle_distance, max_obstacle_distance)
		spawn_obstacle_at_x_position(last_obstacle_x)
		return

	# Calculate distance from last obstacle to right edge of screen
	var distance_to_screen_edge = screen_size.x - last_obstacle_x

	# If we're getting close to the screen edge, spawn a new obstacle
	if distance_to_screen_edge < min_obstacle_distance:
		var next_spawn_x = last_obstacle_x + randf_range(min_obstacle_distance, max_obstacle_distance)
		spawn_obstacle_at_x_position(next_spawn_x)

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
	var obstacle_scene = selected_type["scene"]
	var obstacle = obstacle_scene.instantiate()
	get_tree().current_scene.add_child(obstacle)

	# Apply stage-specific height/offset parameters before setup
	_apply_stage_height_params_to_obstacle(obstacle, selected_type["name"])

	# Set up the obstacle with shared movement speed
	obstacle.set_movement_speed(obstacle_movement_speed)
	obstacle.setup_obstacle(screen_size.x, screen_size.y)

	# Increment obstacle counter
	obstacle_count += 1

	# Notify StageManager of obstacle spawn (for stage progression tracking)
	if StageManager:
		StageManager.on_obstacle_spawned()

	# Emit signal for nest spawner to handle
	obstacle_spawned.emit(obstacle)

	print("🏔️  Spawned ", selected_type["name"], " | Total obstacles: ", obstacle_count)

func spawn_obstacle_at_x_position(spawn_x: float):
	"""Spawn an obstacle at a specific X position"""
	if obstacle_types.is_empty():
		print("Error: No obstacle types available!")
		return

	# Select random obstacle type using weighted selection
	var selected_type = _get_weighted_random_obstacle_type()
	if not selected_type:
		print("Error: Failed to select obstacle type!")
		return

	# Instantiate the obstacle
	var obstacle_scene = selected_type["scene"]
	var obstacle = obstacle_scene.instantiate()
	get_tree().current_scene.add_child(obstacle)

	# Apply stage-specific height/offset parameters before setup
	_apply_stage_height_params_to_obstacle(obstacle, selected_type["name"])

	# Set up the obstacle with shared movement speed
	obstacle.set_movement_speed(obstacle_movement_speed)
	obstacle.setup_obstacle_at_x_position(screen_size.x, screen_size.y, spawn_x)

	# Update last obstacle position
	last_obstacle_x = spawn_x

	# Increment obstacle counter
	obstacle_count += 1

	# Notify StageManager of obstacle spawn (for stage progression tracking)
	if StageManager:
		StageManager.on_obstacle_spawned()

	# Emit signal for nest spawner to handle
	obstacle_spawned.emit(obstacle)

	print("🏔️  Spawned ", selected_type["name"], " at X=", spawn_x, " | Total obstacles: ", obstacle_count)

func _get_weighted_random_obstacle_type() -> Dictionary:
	"""Select a random obstacle type based on weights"""
	# Calculate total weight
	var total_weight = 0
	for obstacle_type in obstacle_types:
		total_weight += obstacle_type["weight"]
	
	if total_weight <= 0:
		return {}
	
	# Generate random number and find corresponding type
	var random_value = randi_range(1, total_weight)
	var current_weight = 0
	
	for obstacle_type in obstacle_types:
		current_weight += obstacle_type["weight"]
		if random_value <= current_weight:
			return obstacle_type
	
	# Fallback to first type
	return obstacle_types[0]

# STAGE MANAGER INTEGRATION ===============================================

func _connect_to_stage_manager():
	"""Connect to StageManager for automatic stage-based parameter updates"""
	if StageManager:
		StageManager.stage_changed.connect(_on_stage_changed)
		print("🔗 ObstacleSpawner connected to StageManager")
		
		# Apply current stage configuration immediately
		if StageManager.current_stage_config:
			apply_stage_config(StageManager.current_stage_config)
	else:
		print("⚠️  StageManager not available - using default parameters")

func _on_stage_changed(new_stage: int, config: StageConfiguration):
	"""Handle stage changes from StageManager"""
	print("🏔️  ObstacleSpawner: Updating to Stage ", new_stage)
	apply_stage_config(config)

func apply_stage_config(config: StageConfiguration):
	"""Apply stage configuration parameters to obstacle spawning"""
	if not config:
		print("⚠️  No stage configuration provided")
		return

	current_stage_config = config

	# Update obstacle weights
	mountain_weight = config.mountain_weight
	stalactite_weight = config.stalactite_weight
	floating_island_weight = config.floating_island_weight

	# Update world/movement speed
	obstacle_movement_speed = config.world_speed

	# Update distance parameters
	min_obstacle_distance = config.min_obstacle_distance
	max_obstacle_distance = config.max_obstacle_distance
	same_obstacle_repeat_chance = config.same_obstacle_repeat_chance

	# Refresh obstacle types with new weights
	_setup_obstacle_types()

	print("🏔️  Stage config applied:")
	print("   - World speed: ", obstacle_movement_speed)
	print("   - Mountain weight: ", mountain_weight)
	print("   - Stalactite weight: ", stalactite_weight)
	print("   - Island weight: ", floating_island_weight)
	print("   - Distance range: ", min_obstacle_distance, "-", max_obstacle_distance)

func _apply_stage_height_params_to_obstacle(obstacle: Node, obstacle_type_name: String):
	"""Apply stage-specific height/offset parameters to an obstacle"""
	if not current_stage_config:
		return
		
	# Apply parameters based on obstacle type
	if obstacle_type_name.begins_with("Mountain"):
		# Apply mountain height parameters (stage calls them heights, mountain script calls them offsets)
		if obstacle.has_method("set_height_range"):
			obstacle.set_height_range(current_stage_config.mountain_min_height, current_stage_config.mountain_max_height)
		elif "min_mountain_offset" in obstacle and "max_mountain_offset" in obstacle:
			# Map stage height values to mountain offset values
			obstacle.min_mountain_offset = current_stage_config.mountain_min_height
			obstacle.max_mountain_offset = current_stage_config.mountain_max_height
			print("🏔️  Applied mountain heights: ", current_stage_config.mountain_min_height, "-", current_stage_config.mountain_max_height)
	
	elif obstacle_type_name == "Stalactite":
		# Apply stalactite height parameters
		if obstacle.has_method("set_height_range"):
			obstacle.set_height_range(current_stage_config.stalactite_min_height, current_stage_config.stalactite_max_height)
		elif "min_stalactite_height" in obstacle and "max_stalactite_height" in obstacle:
			obstacle.min_stalactite_height = current_stage_config.stalactite_min_height
			obstacle.max_stalactite_height = current_stage_config.stalactite_max_height
			print("🗻 Applied stalactite heights: ", current_stage_config.stalactite_min_height, "-", current_stage_config.stalactite_max_height)
	
	elif obstacle_type_name == "FloatingIsland" or obstacle_type_name.find("Island") != -1:
		# Apply floating island offset parameters
		if obstacle.has_method("set_offset_range"):
			obstacle.set_offset_range(current_stage_config.floating_island_minimum_top_offset, current_stage_config.floating_island_minimum_bottom_offset)
		elif "minimum_top_offset" in obstacle and "minimum_bottom_offset" in obstacle:
			obstacle.minimum_top_offset = current_stage_config.floating_island_minimum_top_offset
			obstacle.minimum_bottom_offset = current_stage_config.floating_island_minimum_bottom_offset
			print("🏝️  Applied island offsets: ", current_stage_config.floating_island_minimum_top_offset, "-", current_stage_config.floating_island_minimum_bottom_offset)

# TESTING AND DEBUG METHODS ===============================================

# Method to manually spawn obstacle (for testing)
func spawn_obstacle_now():
	spawn_random_obstacle()

# NOTE: Difficulty level now managed by StageManager

