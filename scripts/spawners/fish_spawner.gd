extends Node2D

class_name FishSpawner

## Spawns fish with stage-based configuration and pre-nest boost system
## Fish spawning is now controlled by the StageManager system

@export var fish_scene: PackedScene  # Drag your Fish.tscn here
@export var eagle_reference: Eagle

# Fish spawn parameters (now controlled by StageManager)
var spawn_interval: float = 5.0  # Seconds between spawns
var spawn_interval_variance: float = 2.0  # Random variation in timing
var min_spawn_interval: float = 2.0  # Minimum time between spawns
var fish_enabled: bool = false  # Whether fish spawning is enabled in current stage

# Fish boost before nest system
@export_group("Pre-Nest Fish Boost")
@export var boost_enabled: bool = true  # Enable fish boost before nest spawns
@export var boost_trigger_obstacles: int = 2  # How many obstacles before nest to start boost
@export var boost_spawn_interval: float = 1.5  # Spawn interval during boost (faster)
@export var boost_duration: float = 8.0  # How long boost lasts (seconds)
@export var min_fish_guaranteed: int = 2  # Minimum fish to spawn during boost period

var spawn_timer: Timer
var screen_size: Vector2
var nest_spawner: NestSpawner
var is_boosting: bool = false
var boost_timer: Timer
var fish_spawned_during_boost: int = 0

# Stage configuration tracking
var current_stage_config: StageConfiguration

func _ready():
	# Find the eagle (you can also drag and drop this in the inspector)
	eagle_reference = get_tree().current_scene.find_child("Eagle", true, false)
	if not eagle_reference:
		return
	
	# Find nest spawner for boost coordination
	nest_spawner = get_tree().current_scene.find_child("NestSpawner", true, false)
	if nest_spawner and boost_enabled:
		nest_spawner.nest_incoming.connect(_on_nest_incoming)
	elif boost_enabled:
		pass
	
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Create and configure spawn timer (will start when fish are enabled via stage config)
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	# Note: Timer will be started by apply_stage_config() when fish are enabled
	
	# Create boost timer
	boost_timer = Timer.new()
	boost_timer.one_shot = true
	add_child(boost_timer)
	boost_timer.timeout.connect(_on_boost_timeout)
	
	# Connect to StageManager for stage-based configuration
	_connect_to_stage_manager()
	
func _on_spawn_timer_timeout():
	# Only spawn fish if enabled in current stage
	if fish_enabled:
		spawn_fish()
		
		# Count fish spawned during boost
		if is_boosting:
			fish_spawned_during_boost += 1
	
	# Set next spawn interval based on boost state
	var base_interval = boost_spawn_interval if is_boosting else spawn_interval
	var variance = spawn_interval_variance * 0.5 if is_boosting else spawn_interval_variance
	
	var next_interval = base_interval + randf_range(-variance, variance)
	next_interval = max(next_interval, min_spawn_interval)
	spawn_timer.wait_time = next_interval
	spawn_timer.start()

func spawn_fish():
	if not fish_scene:
		print("Error: No fish scene assigned to spawner!")
		return
	
	if not eagle_reference:
		print("Error: No eagle reference available!")
		return
	
	# Use the Fish's static spawn method with eagle reference
	var _fish = Fish.spawn_fish_at_bottom(get_tree(), fish_scene, eagle_reference, screen_size.x, screen_size.y)

# STAGE MANAGER INTEGRATION ===============================================

func _connect_to_stage_manager():
	"""Connect to StageManager for automatic stage-based parameter updates"""
	if StageManager:
		StageManager.stage_changed.connect(_on_stage_changed)
		# Apply current stage configuration immediately
		if StageManager.current_stage_config:
			apply_stage_config(StageManager.current_stage_config)
	else:
		pass

func _on_stage_changed(new_stage: int, config: StageConfiguration):
	"""Handle stage changes from StageManager"""
	apply_stage_config(config)

func apply_stage_config(config: StageConfiguration):
	"""Apply stage configuration parameters to fish spawning"""
	if not config:
		print("⚠️  No stage configuration provided")
		return
		
	current_stage_config = config
	
	# Update fish enabled/disabled state
	fish_enabled = config.fish_enabled
	
	# Update fish spawn intervals
	spawn_interval = config.fish_min_spawn_interval if config.fish_enabled else 999.0  # Very long if disabled
	spawn_interval_variance = (config.fish_max_spawn_interval - config.fish_min_spawn_interval) / 2.0
	min_spawn_interval = config.fish_min_spawn_interval
	
	# Update spawn timer with new interval
	if spawn_timer and config.fish_enabled:
		# Calculate a proper initial interval
		var initial_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
		initial_interval = max(initial_interval, min_spawn_interval)
		spawn_timer.wait_time = initial_interval
		spawn_timer.start()  # Start timer when fish are enabled
	elif spawn_timer and not config.fish_enabled:
		# Stop spawning if fish are disabled
		spawn_timer.stop()
	
# TESTING AND DEBUG METHODS ===============================================

# Method to manually spawn fish (for testing)
func spawn_fish_now():
	if fish_enabled:
		spawn_fish()
	else:
		pass

# Method to manually test boost system (for debugging)
func test_boost_system():
	start_fish_boost()
	await get_tree().create_timer(3.0).timeout  # Wait 3 seconds
	end_fish_boost()

# Pre-nest boost system
func _on_nest_incoming(obstacles_remaining: int):
	"""Called when nest is incoming - start fish boost if needed"""
	if not boost_enabled or not fish_enabled:
		return
	
	if obstacles_remaining <= boost_trigger_obstacles and not is_boosting:
		start_fish_boost()

func start_fish_boost():
	"""Start boosted fish spawning before nest appears"""
	if is_boosting or not fish_enabled:
		return
	
	is_boosting = true
	fish_spawned_during_boost = 0
	
	# Restart spawn timer with boost interval
	spawn_timer.stop()
	spawn_timer.wait_time = boost_spawn_interval
	spawn_timer.start()
	
	# Start boost duration timer
	boost_timer.wait_time = boost_duration
	boost_timer.start()
	
	# Immediately spawn a fish to give instant opportunity
	spawn_fish()
	fish_spawned_during_boost += 1

func _on_boost_timeout():
	"""Called when boost duration ends"""
	end_fish_boost()

func end_fish_boost():
	"""End boosted fish spawning and return to normal"""
	if not is_boosting:
		return
	
	is_boosting = false
	
	# Ensure minimum fish were spawned
	if fish_spawned_during_boost < min_fish_guaranteed:
		var missing_fish = min_fish_guaranteed - fish_spawned_during_boost
		for i in range(missing_fish):
			spawn_fish()
			await get_tree().create_timer(0.5).timeout  # Small delay between guaranteed spawns
	
	# Return to normal spawn timing
	spawn_timer.stop()
	var normal_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
	normal_interval = max(normal_interval, min_spawn_interval)
	spawn_timer.wait_time = normal_interval
	spawn_timer.start()
