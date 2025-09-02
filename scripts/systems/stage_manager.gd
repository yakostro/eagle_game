extends Node

## Central singleton for managing stage progression and difficulty balancing
## Controls stage transitions and applies stage parameters to all spawners

# Current stage tracking
var current_stage: int = 1
var current_stage_config: StageConfiguration
var stage_timer: float = 0.0
var stage_nest_count: int = 0
var auto_difficulty_enabled: bool = false

# Debug tracking
var total_obstacles_spawned: int = 0
var total_nests_spawned: int = 0

# Signals for stage progression
signal stage_changed(new_stage: int, stage_config: StageConfiguration)
signal auto_difficulty_started()
signal stage_completed(completed_stage: int)

func _ready():
	print("🎯 StageManager singleton initialized")
	print("   Starting stage: ", current_stage)
	print("   Auto-difficulty: ", "DISABLED" if not auto_difficulty_enabled else "ENABLED")
	
	# Debug: Check if StageConfiguration class is available
	print("🔍 Checking class registration...")
	var test_config = StageConfiguration.new()
	if test_config:
		print("✅ StageConfiguration class is accessible")
		# Test basic properties
		test_config.stage_name = "Test"
		test_config.world_speed = 250.0
		print("✅ StageConfiguration properties work: ", test_config.stage_name, " @ ", test_config.world_speed)
		# Resources are automatically garbage collected, no queue_free() needed
	else:
		print("❌ StageConfiguration class not accessible")
	
	# Load the initial stage (Stage 1)
	print("🔄 Loading initial stage...")
	if not load_stage(1):
		push_error("StageManager: Failed to load initial stage 1!")
		print("🆘 CRITICAL: Initial stage loading failed - system will be non-functional")
	else:
		print("✅ Initial stage loaded successfully")
	
	# Set process to handle stage timing
	set_process(true)

func _process(delta: float):
	# Handle stage timer progression
	if not auto_difficulty_enabled:
		stage_timer += delta
		_check_stage_completion()
		
		# Debug output every 2 seconds during timer-based stages (Task 7)
		if current_stage_config and current_stage_config.completion_type == StageConfiguration.CompletionType.TIMER:
			var time_remaining = current_stage_config.completion_value - stage_timer
			if time_remaining > 0 and int(stage_timer * 0.5) % 1 == 0 and abs(stage_timer - round(stage_timer * 2) / 2) < delta:
				print("⏱️  Stage %d: %.1fs / %.1fs (%.1fs remaining)" % [current_stage, stage_timer, current_stage_config.completion_value, time_remaining])

## Get current stage number
func get_current_stage() -> int:
	return current_stage

## Get current stage configuration
func get_current_stage_config() -> StageConfiguration:
	return current_stage_config

## Load a specific stage configuration
func load_stage(stage_number: int) -> bool:
	print("📋 StageManager: Loading stage %d..." % stage_number)
	
	# Construct file path for stage configuration
	var stage_file_path = _get_stage_file_path(stage_number)
	
	# Enhanced debugging to understand the loading issue
	print("🔍 StageManager: Checking for resource: ", stage_file_path)
	print("🔍 Trying ResourceLoader.exists(): ", ResourceLoader.exists(stage_file_path))
	print("🔍 Trying FileAccess.file_exists(): ", FileAccess.file_exists(stage_file_path))
	
	# Try both loading methods to see which one works
	print("🔄 StageManager: Loading resource from: ", stage_file_path)
	print("🔍 Trying basic load()...")
	var raw_resource = load(stage_file_path)
	print("🔍 Basic load() result: ", raw_resource)
	print("🔍 Basic load() type: ", raw_resource.get_class() if raw_resource else "null")
	
	if not raw_resource:
		print("🔍 Trying ResourceLoader.load()...")
		raw_resource = ResourceLoader.load(stage_file_path)
		print("🔍 ResourceLoader.load() result: ", raw_resource)
		print("🔍 ResourceLoader.load() type: ", raw_resource.get_class() if raw_resource else "null")
	
	if not raw_resource:
		push_error("StageManager: Failed to load .tres file - resource is null")
		print("❌ This usually means the .tres file has a broken script reference or format issue")
		print("🧪 Testing if StageConfiguration class works manually...")
		var test_config = StageConfiguration.new()
		if test_config:
			print("✅ StageConfiguration class works manually")
			test_config.stage_name = "Manual Test"
			print("✅ StageConfiguration properties work: ", test_config.stage_name)
		else:
			print("❌ StageConfiguration class fails even manually")
		return false
	
	var loaded_config = raw_resource as StageConfiguration
	if not loaded_config:
		push_error("StageManager: Failed to cast resource to StageConfiguration")
		print("❌ Resource casting failed - raw resource: ", raw_resource)
		print("❌ Expected StageConfiguration, got: ", raw_resource.get_class() if raw_resource else "null")
		return false
	print("✅ Resource loaded and cast successfully, validating...")
	
	# Validate the loaded configuration
	print("🔍 Validating configuration...")
	var validation_result = loaded_config.validate_parameters()
	print("🔍 Validation result: ", validation_result)
	if not validation_result:
		push_error("StageManager: Stage %d configuration failed validation" % stage_number)
		return false
	print("✅ Configuration validated successfully")
	
	# Check that stage numbers match (consistency check)
	if loaded_config.stage_number != stage_number:
		push_warning("StageManager: Stage file number mismatch. Expected: %d, Got: %d" % [stage_number, loaded_config.stage_number])
	
	# Apply the loaded configuration
	current_stage_config = loaded_config
	current_stage = stage_number
	
	print("✅ StageManager: Successfully loaded stage %d - %s" % [stage_number, loaded_config.stage_name])
	print("   World Speed: %.1f" % loaded_config.world_speed)
	print("   Fish Enabled: %s" % str(loaded_config.fish_enabled))
	print("   Nests Enabled: %s" % str(loaded_config.nests_enabled))
	print("   Completion: %s (%.1f)" % [
		"TIMER" if loaded_config.completion_type == StageConfiguration.CompletionType.TIMER else "NESTS",
		loaded_config.completion_value
	])
	
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
		return "res://scenes/configs/stages/" + stage_file_names[stage_number]
	else:
		# Fallback for future stages
		return "res://scenes/configs/stages/stage_%02d.tres" % stage_number

## Advance to the next stage
func advance_to_next_stage():
	var next_stage = current_stage + 1
	
	print("⬆️  StageManager: Advancing from stage %d to stage %d" % [current_stage, next_stage])
	
	# Check if we've reached the final manual stage
	if next_stage > 6:
		print("🎉 All manual stages completed! Enabling auto-difficulty system...")
		enable_auto_difficulty()
		return
	
	# Try to load the next stage
	if load_stage(next_stage):
		# Reset stage progress counters
		stage_timer = 0.0
		stage_nest_count = 0
		
		print("✨ Successfully advanced to Stage %d: %s" % [current_stage, current_stage_config.stage_name])
		
		# Emit stage changed signal for other systems to react
		stage_changed.emit(current_stage, current_stage_config)
		
	else:
		push_error("StageManager: Failed to advance to stage %d!" % next_stage)
		print("🛑 Stage progression halted due to loading failure")

## Check if current stage is complete
func _check_stage_completion():
	if not current_stage_config:
		return
	
	var is_complete = false
	var completion_reason = ""
	
	# Check completion based on stage type
	if current_stage_config.completion_type == StageConfiguration.CompletionType.TIMER:
		# Timer-based completion
		if stage_timer >= current_stage_config.completion_value:
			is_complete = true
			completion_reason = "timer reached %.1fs" % current_stage_config.completion_value
	elif current_stage_config.completion_type == StageConfiguration.CompletionType.NESTS_SPAWNED:
		# Nest-based completion
		if stage_nest_count >= current_stage_config.completion_value:
			is_complete = true
			completion_reason = "spawned %d nests" % int(current_stage_config.completion_value)
	
	# Advance to next stage if complete
	if is_complete:
		print("🎯 Stage %d COMPLETED: %s" % [current_stage, completion_reason])
		stage_completed.emit(current_stage)
		advance_to_next_stage()

## Called when an obstacle is spawned (for nest-based completion tracking)
func on_obstacle_spawned():
	total_obstacles_spawned += 1

## Called when a nest is spawned (for nest-based completion tracking)
func on_nest_spawned():
	total_nests_spawned += 1
	stage_nest_count += 1
	
	# Debug output for nest-based stages (Task 7)
	if current_stage_config and current_stage_config.completion_type == StageConfiguration.CompletionType.NESTS_SPAWNED:
		var nests_remaining = int(current_stage_config.completion_value) - stage_nest_count
		print("🏠 Stage %d: %d / %d nests spawned (%d remaining)" % [current_stage, stage_nest_count, int(current_stage_config.completion_value), nests_remaining])

## Enable automatic difficulty progression
func enable_auto_difficulty():
	print("🔥 StageManager: Auto-difficulty ENABLED")
	auto_difficulty_enabled = true
	auto_difficulty_started.emit()

## Disable automatic difficulty progression
func disable_auto_difficulty():
	print("🛑 StageManager: Auto-difficulty DISABLED")
	auto_difficulty_enabled = false

## Reset StageManager to Stage 1 (for restarts)
func reset_to_stage_one():
	print("🔄 StageManager: Resetting to Stage 1 for restart")
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
	print("🔄 StageManager: Stage progress reset")

## Force advance to next stage (for testing)
func force_advance_stage():
	print("🧪 TESTING: Forcing stage advancement...")
	advance_to_next_stage()

## Skip to a specific stage (for testing)
func skip_to_stage(stage_number: int) -> bool:
	print("🧪 TESTING: Skipping to stage %d..." % stage_number)
	if load_stage(stage_number):
		stage_timer = 0.0
		stage_nest_count = 0
		print("✅ Skipped to Stage %d: %s" % [current_stage, current_stage_config.stage_name])
		stage_changed.emit(current_stage, current_stage_config)
		return true
	else:
		print("❌ Failed to skip to stage %d" % stage_number)
		return false
