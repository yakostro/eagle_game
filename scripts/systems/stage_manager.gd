extends Node

## Central singleton for managing stage progression and difficulty balancing
## Controls stage transitions and applies stage parameters to all spawners

# Current stage tracking
var current_stage: int = 1
var current_stage_config: StageConfiguration
var stage_timer: float = 0.0
var stage_nest_count: int = 0
var auto_difficulty_enabled: bool = false

# Stage system activation
var stage_system_active: bool = false

# Auto-difficulty system
var auto_difficulty_system: AutoDifficultySystem

# Debug tracking
var total_obstacles_spawned: int = 0
var total_nests_spawned: int = 0

# Signals for stage progression
signal stage_changed(new_stage: int, stage_config: StageConfiguration)
signal auto_difficulty_started()
signal stage_completed(completed_stage: int)

func _ready():
	# Connect auto-difficulty signal to handler
	auto_difficulty_started.connect(_on_auto_difficulty_started)

	# Load the initial stage (Stage 1) but don't start timing yet
	if not load_stage(1):
		push_error("StageManager: Failed to load initial stage 1!")

	# Don't start processing until stage system is activated
	set_process(false)

func _process(delta: float):
	# Only process if stage system is active
	if not stage_system_active:
		return
		
	# Handle stage timer progression for manual stages
	if not auto_difficulty_enabled:
		stage_timer += delta
		_check_stage_completion()
	else:
		# Handle auto-difficulty progression
		if auto_difficulty_system:
			auto_difficulty_system.update(delta)

## Get current stage number
func get_current_stage() -> int:
	return current_stage

## Get current stage configuration
func get_current_stage_config() -> StageConfiguration:
	return current_stage_config

## Activate the stage progression system (called by game scene when it starts)
func activate_stage_system():
	if stage_system_active:
		print("StageManager: Stage system already active")
		return
	
	stage_system_active = true
	print("StageManager: Stage system activated - Stage progression started")
	
	# Reset timers to ensure clean start
	stage_timer = 0.0
	stage_nest_count = 0
	
	# Start processing for stage timing
	set_process(true)
	
	# Emit initial stage signal to inform all spawners about current configuration
	stage_changed.emit(current_stage, current_stage_config)

## Deactivate the stage progression system (for pausing or game over)
func deactivate_stage_system():
	stage_system_active = false
	set_process(false)
	print("StageManager: Stage system deactivated")

## Load a specific stage configuration
func load_stage(stage_number: int) -> bool:
	# Construct file path for stage configuration
	var stage_file_path = _get_stage_file_path(stage_number)

	var raw_resource = load(stage_file_path)
	if not raw_resource:
		raw_resource = ResourceLoader.load(stage_file_path)

	if not raw_resource:
		push_error("StageManager: Failed to load .tres file - resource is null")
		return false

	var loaded_config = raw_resource as StageConfiguration
	if not loaded_config:
		push_error("StageManager: Failed to cast resource to StageConfiguration")
		return false

	# Validate the loaded configuration
	var validation_result = loaded_config.validate_parameters()
	if not validation_result:
		push_error("StageManager: Stage %d configuration failed validation" % stage_number)
		return false

	# Check that stage numbers match (consistency check)
	if loaded_config.stage_number != stage_number:
		push_warning("StageManager: Stage file number mismatch. Expected: %d, Got: %d" % [stage_number, loaded_config.stage_number])

	# Apply the loaded configuration
	current_stage_config = loaded_config
	current_stage = stage_number

	return true

## Get the file path for a stage configuration
func _get_stage_file_path(stage_number: int) -> String:
	# Map stage numbers to their specific file names
	var stage_file_names = {
		1: "stage_01_introduction.tres",
		2: "stage_02_fish_intro.tres",
		3: "stage_03_nest_intro.tres", 
		4: "stage_04_stalactites.tres",
		5: "stage_05_harder.tres",
		6: "stage_06_final.tres"
	}
	
	if stage_number in stage_file_names:
		return "res://configs/stages/" + stage_file_names[stage_number]
	else:
		# Fallback for future stages
		return "res://configs/stages/stage_%02d.tres" % stage_number

## Advance to the next stage
func advance_to_next_stage():
	var next_stage = current_stage + 1

	# Check if we've reached the final manual stage
	if next_stage > 6:
		enable_auto_difficulty()
		return

	# Try to load the next stage
	if load_stage(next_stage):
		# Reset stage progress counters
		stage_timer = 0.0
		stage_nest_count = 0

		# Emit stage changed signal for other systems to react
		stage_changed.emit(current_stage, current_stage_config)

	else:
		push_error("StageManager: Failed to advance to stage %d!" % next_stage)

## Check if current stage is complete
func _check_stage_completion():
	if not current_stage_config:
		return
	
	var is_complete = false
	var _completion_reason = ""
	
	# Check completion based on stage type
	if current_stage_config.completion_type == StageConfiguration.CompletionType.TIMER:
		# Timer-based completion
		if stage_timer >= current_stage_config.completion_value:
			is_complete = true
			_completion_reason = "timer reached %.1fs" % current_stage_config.completion_value
	elif current_stage_config.completion_type == StageConfiguration.CompletionType.NESTS_SPAWNED:
		# Nest-based completion
		if stage_nest_count >= current_stage_config.completion_value:
			is_complete = true
			_completion_reason = "spawned %d nests" % int(current_stage_config.completion_value)
	
	# Advance to next stage if complete
	if is_complete:
		stage_completed.emit(current_stage)
		advance_to_next_stage()

## Called when an obstacle is spawned (for nest-based completion tracking)
func on_obstacle_spawned():
	total_obstacles_spawned += 1

## Called when a nest is spawned (for nest-based completion tracking)
func on_nest_spawned():
	total_nests_spawned += 1
	stage_nest_count += 1

## Enable automatic difficulty progression
func enable_auto_difficulty():
	auto_difficulty_enabled = true
	auto_difficulty_started.emit()

## Handle auto-difficulty started signal
func _on_auto_difficulty_started():
	if not current_stage_config:
		push_error("StageManager: Cannot start auto-difficulty without a current stage config!")
		return

	# Create the auto-difficulty system
	auto_difficulty_system = AutoDifficultySystem.new()
	if not auto_difficulty_system:
		push_error("StageManager: Failed to create AutoDifficultySystem!")
		return

	# Initialize with the current stage (Stage 6) as baseline
	auto_difficulty_system.initialize_with_base_config(current_stage_config)

	# Connect to auto-difficulty progression signals
	auto_difficulty_system.difficulty_increased.connect(_on_auto_difficulty_increased)
	auto_difficulty_system.parameter_capped.connect(_on_auto_difficulty_parameter_capped)

	# Generate and apply the first auto-difficulty configuration (Level 0)
	_apply_auto_difficulty_config()

## Handle auto-difficulty level increase
func _on_auto_difficulty_increased(_new_level: int):
	_apply_auto_difficulty_config()

## Handle auto-difficulty parameter capping
func _on_auto_difficulty_parameter_capped(_parameter_name: String, _capped_value: float):
	pass

## Apply current auto-difficulty configuration to all spawners
func _apply_auto_difficulty_config():
	if not auto_difficulty_system:
		push_error("StageManager: Cannot apply auto-difficulty config - system not initialized!")
		return
	
	# Generate the current auto-difficulty configuration
	var auto_config = auto_difficulty_system.get_modified_config()
	if not auto_config:
		push_error("StageManager: Failed to generate auto-difficulty configuration!")
		return
	
	# Update current stage tracking
	current_stage = auto_config.stage_number
	current_stage_config = auto_config

	# Emit stage_changed signal so all spawners update
	stage_changed.emit(current_stage, current_stage_config)

## Get auto-difficulty statistics for UI display
func get_auto_difficulty_stats() -> Dictionary:
	if auto_difficulty_system:
		return auto_difficulty_system.get_difficulty_stats()
	else:
		return {}

## Disable automatic difficulty progression
func disable_auto_difficulty():
	auto_difficulty_enabled = false

	# Clean up auto-difficulty system
	if auto_difficulty_system:
		auto_difficulty_system = null

## Reset StageManager to Stage 1 (for restarts)
func reset_to_stage_one():
	# Deactivate stage system first
	deactivate_stage_system()
	# Ensure auto-difficulty is off
	disable_auto_difficulty()
	# Reset counters
	total_obstacles_spawned = 0
	total_nests_spawned = 0
	stage_timer = 0.0
	stage_nest_count = 0
	# Load Stage 1 config
	load_stage(1)

## Get debug information about current stage state
func get_debug_info() -> String:
	var info = "StageManager Debug Info:\n"
	info += "  Current Stage: %d\n" % current_stage
	info += "  Stage System: %s\n" % ("ACTIVE" if stage_system_active else "INACTIVE")
	info += "  Stage Timer: %.1fs\n" % stage_timer
	info += "  Stage Nests: %d\n" % stage_nest_count
	info += "  Total Obstacles: %d\n" % total_obstacles_spawned
	info += "  Total Nests: %d\n" % total_nests_spawned
	info += "  Auto-difficulty: %s\n" % ("ON" if auto_difficulty_enabled else "OFF")
	
	if current_stage_config:
		info += "  Stage Config Loaded: ✓\n"
		info += "    Name: %s\n" % current_stage_config.stage_name
		info += "    World Speed: %.1f\n" % current_stage_config.world_speed
		info += "    Fish: %s\n" % ("ON" if current_stage_config.fish_enabled else "OFF")
		info += "    Nests: %s\n" % ("ON" if current_stage_config.nests_enabled else "OFF")
		var completion_type_str = "TIMER" if current_stage_config.completion_type == StageConfiguration.CompletionType.TIMER else "NESTS"
		info += "    Completion: %s (%.1f)" % [completion_type_str, current_stage_config.completion_value]
	else:
		info += "  Stage Config: ✗ NOT LOADED"
	
	return info

## Reset stage progress (for testing)
func reset_stage_progress():
	stage_timer = 0.0
	stage_nest_count = 0

## Force advance to next stage (for testing)
func force_advance_stage():
	advance_to_next_stage()

## Skip to a specific stage (for testing)
func skip_to_stage(stage_number: int) -> bool:
	if load_stage(stage_number):
		stage_timer = 0.0
		stage_nest_count = 0
		stage_changed.emit(current_stage, current_stage_config)
		return true
	else:
		return false

## Force trigger auto-difficulty (for testing)
func force_trigger_auto_difficulty():
	if auto_difficulty_enabled:
		return false

	# Make sure we're on Stage 6 first
	if current_stage != 6:
		if not load_stage(6):
			return false

	# Trigger auto-difficulty
	enable_auto_difficulty()
	return true
