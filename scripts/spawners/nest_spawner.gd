class_name NestSpawner
extends Node

## Spawns nests on obstacles based on stage configuration
## Nest spawning is now controlled by the StageManager system

@export var nest_scene: PackedScene  # Drag your Nest.tscn here
@export var eagle_reference: Eagle  # Reference to the eagle for signal connections

# Nest spawn parameters (now controlled by StageManager)
var min_skipped_obstacles: int = 3  # Minimum obstacles to skip before spawning nest
var max_skipped_obstacles: int = 6  # Maximum obstacles to skip before spawning nest
var warn_before_obstacles: int = 1  # How many obstacles before the nest to warn the player
var nests_enabled: bool = false  # Whether nest spawning is enabled in current stage

# Nest spawning system variables
var obstacles_since_last_nest: int = 0  # Track obstacles spawned since last nest
var next_nest_spawn_target: int = 0  # How many obstacles to skip before next nest
var warned_this_cycle: bool = false

# Stage configuration tracking
var current_stage_config: StageConfiguration
var total_nests_spawned: int = 0  # Track total nests for stage progression

signal nest_incoming(obstacles_remaining: int)
signal nest_spawned(nest: Node)

func _ready():
	# Initialize nest spawn target (will be updated when stage config is applied)
	_set_next_nest_spawn_target()

	print("🏠 Nest spawner initialized")
	print("   Current nest difficulty: min=", min_skipped_obstacles, " max=", max_skipped_obstacles)
	print("   First nest will spawn after ", next_nest_spawn_target, " obstacles")
	
	# Connect to StageManager for stage-based configuration
	_connect_to_stage_manager()


func on_obstacle_spawned(obstacle: BaseObstacle):
	"""Called when an obstacle is spawned - decide if it should get a nest"""
	if not obstacle:
		print("Warning: null obstacle passed to nest spawner")
		return
	
	# Only process nests if enabled in current stage
	if not nests_enabled:
		return
	
	# Increment counter
	obstacles_since_last_nest += 1

	# Emit a heads-up when we are close to the spawn target
	var remaining: int = next_nest_spawn_target - obstacles_since_last_nest
	if not warned_this_cycle and remaining <= warn_before_obstacles and remaining >= 0:
		nest_incoming.emit(max(remaining, 0))
		warned_this_cycle = true
	
	# Check if this obstacle should get a nest
	if _should_spawn_nest_on_obstacle(obstacle):
		spawn_nest_on_obstacle(obstacle)
		# Reset counter and set new random target
		obstacles_since_last_nest = 0
		_set_next_nest_spawn_target()
	
	print("🏠 Nest spawner processed ", obstacle.get_obstacle_type(), " | Since last nest: ", obstacles_since_last_nest, "/", next_nest_spawn_target)

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
	
	# Connect nest signals to eagle's energy capacity methods
	nest.nest_fed.connect(eagle_reference.on_nest_fed)
	nest.nest_missed.connect(eagle_reference.on_nest_missed)
	print("   🔗 Connected nest signals to eagle energy capacity system")

	# Track total nests spawned for stage progression
	total_nests_spawned += 1
	
	# Notify StageManager of nest spawn (for stage progression tracking)
	if StageManager:
		StageManager.on_nest_spawned()
	
	# Notify UI or other systems that a nest has spawned
	nest_spawned.emit(nest)
	
	print("🏠 Nest spawned! Total nests: ", total_nests_spawned)

# STAGE MANAGER INTEGRATION ===============================================

func _connect_to_stage_manager():
	"""Connect to StageManager for automatic stage-based parameter updates"""
	if StageManager:
		StageManager.stage_changed.connect(_on_stage_changed)
		print("🔗 NestSpawner connected to StageManager")
		
		# Apply current stage configuration immediately
		if StageManager.current_stage_config:
			apply_stage_config(StageManager.current_stage_config)
	else:
		print("⚠️  StageManager not available - nests disabled by default")

func _on_stage_changed(new_stage: int, config: StageConfiguration):
	"""Handle stage changes from StageManager"""
	print("🏠 NestSpawner: Updating to Stage ", new_stage)
	apply_stage_config(config)

func apply_stage_config(config: StageConfiguration):
	"""Apply stage configuration parameters to nest spawning"""
	if not config:
		print("⚠️  No stage configuration provided")
		return
		
	current_stage_config = config
	
	# Update nest enabled/disabled state
	nests_enabled = config.nests_enabled
	
	# Update nest spawn intervals
	min_skipped_obstacles = config.nest_min_skipped_obstacles
	max_skipped_obstacles = config.nest_max_skipped_obstacles
	
	# Reset nest spawn target with new parameters
	if nests_enabled:
		_set_next_nest_spawn_target()
	
	print("🏠 Stage config applied:")
	print("   - Nests enabled: ", nests_enabled)
	if nests_enabled:
		print("   - Min skipped obstacles: ", min_skipped_obstacles)
		print("   - Max skipped obstacles: ", max_skipped_obstacles)
		print("   - Next nest target: ", next_nest_spawn_target)
	else:
		print("   - Nest spawning disabled")

# TESTING AND DEBUG METHODS ===============================================

func _set_next_nest_spawn_target():
	"""Set random nest spawn target within current difficulty range"""
	next_nest_spawn_target = randi_range(min_skipped_obstacles, max_skipped_obstacles)
	warned_this_cycle = false
	print("   🎯 Next nest will spawn after skipping ", next_nest_spawn_target, " obstacles")
