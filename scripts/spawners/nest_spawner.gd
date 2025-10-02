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

# Multi-placeholder system parameters
@export var nest_visibility_offset: float = 50.0  # Pixels from screen bottom to keep nests visible
@export var debug_placeholder_selection: bool = false  # Show placeholder selection process

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

	
	# Connect to StageManager for stage-based configuration
	_connect_to_stage_manager()


func on_obstacle_spawned(obstacle: BaseObstacle):
	"""Called when an obstacle is spawned - decide if it should get a nest"""
	if not obstacle:
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
	

func _should_spawn_nest_on_obstacle(obstacle: BaseObstacle) -> bool:
	"""Determine if this obstacle should get a nest"""
	# Check if we've reached the target number of skipped obstacles
	if obstacles_since_last_nest < next_nest_spawn_target:
		return false
	
	# Check if this obstacle type can carry nests
	if not obstacle.can_carry_nest:
		return false

	# Get screen dimensions for visibility checking
	var screen_size = get_viewport().get_visible_rect().size

	# Check if obstacle has any visible nest placeholders
	if not obstacle.has_visible_nest_placeholders(screen_size.y, nest_visibility_offset):
		return false
	
	return true

func spawn_nest_on_obstacle(obstacle: BaseObstacle):
	"""Spawn a nest on the given obstacle"""
	if not nest_scene:
		return
	
	if not eagle_reference:
		return
	
	# Instantiate nest
	var nest = nest_scene.instantiate()
	
	# Add nest as child of obstacle so it moves with the obstacle
	obstacle.add_child(nest)
	
	# Position nest using random visible placeholder
	var screen_size = get_viewport().get_visible_rect().size
	var visible_placeholders = obstacle.get_visible_nest_placeholders(screen_size.y, nest_visibility_offset)

	if not visible_placeholders.is_empty():
		# Randomly select one of the visible placeholders
		var selected_placeholder = visible_placeholders[randi() % visible_placeholders.size()]

		# Use the selected placeholder's position
		nest.position = selected_placeholder.position

	else:
		# This shouldn't happen due to visibility check, but just in case
		nest.position = Vector2(0, 20)
	
	# Connect nest signals to eagle's energy capacity methods
	nest.nest_fed.connect(eagle_reference.on_nest_fed)
	nest.nest_missed.connect(eagle_reference.on_nest_missed)

	# Track total nests spawned for stage progression
	total_nests_spawned += 1
	
	# Notify StageManager of nest spawn (for stage progression tracking)
	if StageManager:
		StageManager.on_nest_spawned()
	
	# Notify UI or other systems that a nest has spawned
	nest_spawned.emit(nest)

# STAGE MANAGER INTEGRATION ===============================================

func _connect_to_stage_manager():
	"""Connect to StageManager for automatic stage-based parameter updates"""
	if StageManager:
		StageManager.stage_changed.connect(_on_stage_changed)
		
		# Apply current stage configuration immediately
		if StageManager.current_stage_config:
			apply_stage_config(StageManager.current_stage_config)

func _on_stage_changed(new_stage: int, config: StageConfiguration):
	"""Handle stage changes from StageManager"""
	apply_stage_config(config)

func apply_stage_config(config: StageConfiguration):
	"""Apply stage configuration parameters to nest spawning"""
	if not config:
		return
		
	current_stage_config = config
	
	# Update nest enabled/disabled state
	nests_enabled = config.nests_enabled
	
	# Update nest spawn intervals
	min_skipped_obstacles = config.nest_min_skipped_obstacles
	max_skipped_obstacles = config.nest_max_skipped_obstacles

	# Update visibility offset for multi-placeholder system
	nest_visibility_offset = config.nest_visibility_offset
	
	# Reset nest spawn target with new parameters
	if nests_enabled:
		_set_next_nest_spawn_target()

# TESTING AND DEBUG METHODS ===============================================

func _set_next_nest_spawn_target():
	"""Set random nest spawn target within current difficulty range"""
	next_nest_spawn_target = randi_range(min_skipped_obstacles, max_skipped_obstacles)
	warned_this_cycle = false
