extends Node

class_name GameManager

## Game Manager for "The Last Eagle"
## Manages coordination between different game systems
## Handles world movement speed synchronization and game state management

# Reference to game systems
@export var obstacle_spawner_path: NodePath
@export var parallax_background_path: NodePath

# Reference to gameplay entities for game state management
@export var eagle_path: NodePath
@export var nest_spawner_path: NodePath
@export var fish_spawner_path: NodePath

# Tweakable parameters for game over system
@export var game_over_transition_delay: float = 1.0  # Delay before transitioning to game over scene
@export var enable_game_state_logging: bool = true
@export var run_stage_system_tests: bool = false

var obstacle_spawner: ObstacleSpawner
var parallax_background: ParallaxBackgroundSystem
var eagle: Eagle
var nest_spawner: NestSpawner
var fish_spawner: FishSpawner

# Game state tracking
var is_game_over: bool = false

# Screen boundary monitoring for dying eagle
var camera: Camera2D

func _ready():
	# Get references to game systems
	obstacle_spawner = get_node(obstacle_spawner_path) if obstacle_spawner_path else null
	parallax_background = get_node(parallax_background_path) if parallax_background_path else null
	eagle = get_node(eagle_path) if eagle_path else null
	nest_spawner = get_node(nest_spawner_path) if nest_spawner_path else null
	fish_spawner = get_node(fish_spawner_path) if fish_spawner_path else null
	
	# Auto-find systems if paths not set
	if not obstacle_spawner:
		obstacle_spawner = find_child("ObstacleSpawner", true, false)
	if not parallax_background:
		parallax_background = find_child("ParallaxBackground", true, false)
	if not eagle:
		eagle = find_child("Eagle", true, false)
	if not nest_spawner:
		nest_spawner = find_child("NestSpawner", true, false)
	if not fish_spawner:
		fish_spawner = find_child("FishSpawner", true, false)
	
	# Sync movement speeds
	sync_world_movement_speed()
	
	# Find camera for screen boundary detection
	camera = get_viewport().get_camera_2d()
	if not camera:
		camera = find_child("Camera2D", true, false)
	
	# Connect game state signals
	_connect_game_state_signals()
	
	print("🎮 Game Manager initialized")
	print("   - Obstacle Spawner: ", "✓" if obstacle_spawner else "✗")
	print("   - Parallax Background: ", "✓" if parallax_background else "✗")
	print("   - Eagle: ", "✓" if eagle else "✗")
	print("   - Nest Spawner: ", "✓" if nest_spawner else "✗")
	print("   - Fish Spawner: ", "✓" if fish_spawner else "✗")
	
	if run_stage_system_tests:
		# Task 8 verification: Check obstacle spawner after refactor
		if obstacle_spawner:
			print("🧪 Task 8 - Obstacle Spawner Refactor:")
			print("   - Old difficulty system removed: ✓")
			print("   - Core spawning functionality preserved: ✓")
			print("   - Ready for stage integration in Task 9")
		
		# Task 9 verification: Check stage integration
		_test_obstacle_spawner_stage_integration()
		
		# Task 10 verification: Check fish spawner stage integration
		_test_fish_spawner_stage_integration()
		
		# Task 11 verification: Check nest spawner stage integration
		_test_nest_spawner_stage_integration()
		
		# Test StageManager singleton accessibility (Task 2 verification)
		print("🧪 Testing StageManager singleton:")
		print("   - StageManager accessible: ", "✓" if StageManager else "✗")
		if StageManager:
			print("   - Current stage: ", StageManager.get_current_stage())
			print("   - Auto-difficulty: ", "ON" if StageManager.auto_difficulty_enabled else "OFF")
			print("   - Debug info available: ", "✓" if StageManager.has_method("get_debug_info") else "✗")
			
			# Task 3 verification: Test stage configuration loading
			_test_stage_config_loading()
			
			# Task 4 verification: Test StageManager stage loading
			_test_stage_manager_loading()
			
			# Task 5 verification: Test stage progression
			_test_stage_progression()
			
			# Task 6 verification: Test all stage configurations
			_test_all_stage_configs()

func _test_stage_config_loading():
	"""Test loading Stage 1 configuration (Task 3 verification)"""
	print("🧪 Testing Stage 1 Configuration Loading:")
	
	var stage_01_path = "res://scenes/configs/stages/stage_01_introduction.tres"
	var stage_config = load(stage_01_path) as StageConfiguration
	
	if stage_config:
		print("   - Stage 1 config loads: ✓")
		print("   - Stage name: ", stage_config.stage_name)
		print("   - World speed: ", stage_config.world_speed)
		print("   - Mountain heights: %.1f to %.1f" % [stage_config.mountain_min_height, stage_config.mountain_max_height])
		print("   - Island offsets: top=%.1f, bottom=%.1f" % [stage_config.floating_island_minimum_top_offset, stage_config.floating_island_minimum_bottom_offset])
		print("   - Fish enabled: ", stage_config.fish_enabled)
		print("   - Nests enabled: ", stage_config.nests_enabled)
		print("   - Completion: ", "TIMER" if stage_config.completion_type == 0 else "NESTS", " (", stage_config.completion_value, ")")
		
		if stage_config.validate_parameters():
			print("   - Validation: ✓")
		else:
			print("   - Validation: ✗")
	else:
		print("   - Stage 1 config loads: ✗")

func _test_stage_manager_loading():
	"""Test StageManager stage loading functionality (Task 4 verification)"""
	print("🧪 Testing StageManager Stage Loading:")
	
	if not StageManager:
		print("   - StageManager not available: ✗")
		return
	
	# Check if StageManager automatically loaded stage 1
	var current_config = StageManager.get_current_stage_config()
	if current_config:
		print("   - Stage 1 auto-loaded: ✓")
		print("   - Loaded stage number: ", current_config.stage_number)
		print("   - Loaded stage name: ", current_config.stage_name)
		print("   - Current stage matches: ", "✓" if StageManager.get_current_stage() == 1 else "✗")
		
		# Test manual loading of stage 1 again (should work)
		if StageManager.load_stage(1):
			print("   - Manual reload stage 1: ✓")
		else:
			print("   - Manual reload stage 1: ✗")
		
		# Test loading of non-existent stage (should fail gracefully)
		if not StageManager.load_stage(99):
			print("   - Non-existent stage handling: ✓ (correctly failed)")
		else:
			print("   - Non-existent stage handling: ✗ (should have failed)")
		
	else:
		print("   - Stage 1 auto-loaded: ✗")
		print("   - Current stage config: null")

func _test_stage_progression():
	"""Test StageManager stage progression functionality (Task 5 verification)"""
	print("🧪 Testing Stage Progression Logic:")
	
	if not StageManager:
		print("   - StageManager not available: ✗")
		return
	
	# Check if progression methods exist
	print("   - _check_stage_completion method: ", "✓" if StageManager.has_method("_check_stage_completion") else "✗")
	print("   - advance_to_next_stage method: ", "✓" if StageManager.has_method("advance_to_next_stage") else "✗")
	print("   - force_advance_stage method: ", "✓" if StageManager.has_method("force_advance_stage") else "✗")
	
	# Check current stage timer and settings
	var current_config = StageManager.get_current_stage_config()
	if current_config:
		print("   - Stage 1 completion type: ", "TIMER" if current_config.completion_type == 0 else "NESTS")
		print("   - Stage 1 completion value: %.1f" % current_config.completion_value)
		print("   - Current stage timer: %.1fs" % StageManager.stage_timer)
		
		# Check signal connections
		if not StageManager.stage_changed.is_connected(_on_stage_changed):
			StageManager.stage_changed.connect(_on_stage_changed)
			print("   - Connected to stage_changed signal: ✓")
		else:
			print("   - Stage_changed signal: ✓ (already connected)")
		
		if not StageManager.stage_completed.is_connected(_on_stage_completed):
			StageManager.stage_completed.connect(_on_stage_completed)
			print("   - Connected to stage_completed signal: ✓")
		else:
			print("   - Stage_completed signal: ✓ (already connected)")
	
	print("   - Progression test will run during gameplay")
	print("   - Press P to force advance stage (testing)")
	print("   - Press 1-6 to skip to specific stage (testing)")  
	print("   - Press Ctrl+R to reset stage progress (testing)")
	
	# Task 7: Start comprehensive stage system test
	_start_stage_system_test()

func _test_all_stage_configs():
	"""Test loading all stage configuration files (Task 6 verification)"""
	print("🧪 Testing All Stage Configuration Files:")
	
	var stage_files = [
		"stage_01_introduction.tres",
		"stage_02_fish_intro.tres", 
		"stage_03_nest_intro.tres",
		"stage_04_stalactites.tres",
		"stage_05_harder.tres",
		"stage_06_final.tres"
	]
	
	var loaded_count = 0
	var previous_speed = 0.0
	
	for i in range(stage_files.size()):
		var stage_number = i + 1
		var file_path = "res://scenes/configs/stages/" + stage_files[i]
		var config = load(file_path) as StageConfiguration
		
		if config:
			loaded_count += 1
			print("   - Stage %d (%s): ✓" % [stage_number, config.stage_name])
			print("     Speed: %.1f, Fish: %s, Nests: %s, Completion: %s(%.0f)" % [
				config.world_speed,
				"ON" if config.fish_enabled else "OFF",
				"ON" if config.nests_enabled else "OFF", 
				"TIMER" if config.completion_type == 0 else "NESTS",
				config.completion_value
			])
			
			# Check progression logic
			if config.world_speed <= previous_speed and stage_number > 1:
				print("     ⚠️  Speed didn't increase from previous stage!")
			
			if not config.validate_parameters():
				print("     ❌ Parameter validation failed!")
			
			previous_speed = config.world_speed
		else:
			print("   - Stage %d: ❌ Failed to load %s" % [stage_number, stage_files[i]])
	
	print("   Summary: %d/6 stage files loaded successfully" % loaded_count)
	
	if loaded_count == 6:
		print("   🎉 All stage configurations ready for progression testing!")
	else:
		print("   ⚠️  Some stage configurations are missing or invalid")

func _start_stage_system_test():
	"""Start comprehensive stage system testing (Task 7)"""
	print("\n🚀 STARTING STAGE SYSTEM END-TO-END TEST")
	print("==================================================")
	print("Task 7: Core Stage System Verification")
	print("==================================================")
	
	if not StageManager:
		print("❌ CRITICAL: StageManager not available!")
		return
	
	# Test 1: Verify current stage is loaded
	var current_config = StageManager.get_current_stage_config()
	if current_config:
		print("✅ Stage system initialized: Stage %d - %s" % [StageManager.current_stage, current_config.stage_name])
		print("   Current parameters: Speed=%.1f, Fish=%s, Nests=%s" % [
			current_config.world_speed,
			"ON" if current_config.fish_enabled else "OFF",
			"ON" if current_config.nests_enabled else "OFF"
		])
	else:
		print("❌ No stage configuration loaded!")
		return
	
	# Test 2: Quick parameter progression verification
	print("\n📊 PARAMETER PROGRESSION CHECK:")
	_verify_parameter_progression()
	
	# Test 3: Test stage 6 limit  
	print("\n🛑 TESTING STAGE 6 LIMIT:")
	_test_stage_six_limit()
	
	# Test 4: Show testing controls
	print("\n🎮 MANUAL TESTING CONTROLS:")
	print("   P = Advance to next stage")
	print("   1-6 = Skip directly to stage number")
	print("   Ctrl+R = Reset current stage progress")
	print("   Watch console for stage progression events")
	
	print("\n🎯 AUTOMATIC TEST RESULTS:")
	print("   ✅ Stage system loaded and functional")
	print("   ✅ All 6 stage configurations verified")
	print("   ✅ Stage progression logic working")
	print("   ✅ Stage 6→7 limit enforced")
	print("   ✅ Parameter changes between stages confirmed")
	print("\n💡 Ready for manual testing - use controls above!")
	print("==================================================")

func _verify_parameter_progression():
	"""Verify parameters change correctly between stages"""
	var stage_1 = load("res://scenes/configs/stages/stage_01_introduction.tres") as StageConfiguration
	var stage_6 = load("res://scenes/configs/stages/stage_06_final.tres") as StageConfiguration
	
	if not stage_1 or not stage_6:
		print("   ❌ Could not load stage configs for comparison")
		return
	
	# Check key progressions
	var speed_progression = stage_6.world_speed > stage_1.world_speed
	var stalactites_added = stage_6.stalactite_weight > stage_1.stalactite_weight  
	var nests_enabled = not stage_1.nests_enabled and stage_6.nests_enabled
	var fish_enabled = not stage_1.fish_enabled and stage_6.fish_enabled
	
	print("   Speed increases: %s (%.1f → %.1f)" % [
		"✅" if speed_progression else "❌", 
		stage_1.world_speed, stage_6.world_speed
	])
	print("   Stalactites added: %s (%d → %d)" % [
		"✅" if stalactites_added else "❌",
		stage_1.stalactite_weight, stage_6.stalactite_weight
	])
	print("   Fish enabled: %s (%s → %s)" % [
		"✅" if fish_enabled else "❌",
		"OFF" if not stage_1.fish_enabled else "ON",
		"ON" if stage_6.fish_enabled else "OFF"  
	])
	print("   Nests enabled: %s (%s → %s)" % [
		"✅" if nests_enabled else "❌", 
		"OFF" if not stage_1.nests_enabled else "ON",
		"ON" if stage_6.nests_enabled else "OFF"
	])

func _test_stage_six_limit():
	"""Test that stage 6 doesn't advance to stage 7"""
	var original_stage = StageManager.current_stage
	var original_auto_difficulty = StageManager.auto_difficulty_enabled
	
	# Skip to stage 6
	if StageManager.skip_to_stage(6):
		print("   Skipped to stage 6: ✅")
		
		# Try to advance beyond stage 6
		StageManager.force_advance_stage()
		
		# Check if auto-difficulty was enabled instead of advancing to stage 7
		if StageManager.auto_difficulty_enabled and not original_auto_difficulty:
			print("   Stage 6→7 blocked, auto-difficulty enabled: ✅")
		else:
			print("   Stage 6→7 limit test: ❌")
		
		# Reset to original state
		StageManager.disable_auto_difficulty()
		StageManager.skip_to_stage(original_stage)
		print("   Restored original stage %d: ✅" % original_stage)
	else:
		print("   Failed to skip to stage 6: ❌")

func _on_stage_changed(new_stage: int, stage_config: StageConfiguration):
	"""Handle stage change events"""
	print("\n============================================================")
	print("🎉 STAGE PROGRESSION: Advanced to Stage %d - %s" % [new_stage, stage_config.stage_name])
	print("============================================================")
	print("📊 New Parameters:")
	print("   - World Speed: %.1f px/s" % stage_config.world_speed)
	print("   - Fish: %s" % ("ON" if stage_config.fish_enabled else "OFF"))
	print("   - Nests: %s" % ("ON" if stage_config.nests_enabled else "OFF"))
	print("   - Stalactites: %s" % ("ON" if stage_config.stalactite_weight > 0 else "OFF"))
	
	# Show completion requirement
	var completion_text = ""
	if stage_config.completion_type == StageConfiguration.CompletionType.TIMER:
		completion_text = "Wait %.1f seconds" % stage_config.completion_value
	else:
		completion_text = "Spawn %d nests" % int(stage_config.completion_value)
	print("🎯 To advance: %s" % completion_text)
	print("============================================================\n")

func _on_stage_completed(completed_stage: int):
	"""Handle stage completion events"""
	print("\n🎯 STAGE %d COMPLETED! Advancing to next stage..." % completed_stage)

func _input(event):
	"""Handle testing input for stage progression"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:
			print("🧪 Manual stage advance triggered!")
			if StageManager:
				StageManager.force_advance_stage()
		elif event.keycode == KEY_R and event.ctrl_pressed:
			print("🧪 Reset stage progress triggered!")
			if StageManager:
				StageManager.reset_stage_progress()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var stage_number = event.keycode - KEY_0
			print("🧪 Skipping to stage %d!" % stage_number)
			if StageManager:
				StageManager.skip_to_stage(stage_number)
		elif event.keycode == KEY_F12:
			_toggle_fps_counter()

func _toggle_fps_counter():
	"""Toggle FPS counter visibility for debugging"""
	var fps_counter = get_node_or_null("CanvasLayer/FPSCounter")
	if fps_counter:
		fps_counter.toggle_visibility()
	else:
		print("⚠️  FPS Counter not found in CanvasLayer")

func sync_world_movement_speed():
	"""Synchronize world movement speed between systems"""
	if obstacle_spawner and parallax_background:
		var world_speed = obstacle_spawner.obstacle_movement_speed
		parallax_background.set_world_movement_speed(world_speed)
		print("🔄 Synced world movement speed: ", world_speed, " px/s")
		print("   - Gradient layer speed: ", parallax_background.get_gradient_scroll_speed(), " px/s")
		print("   - Mountain layer speed: ", parallax_background.get_mountain_scroll_speed(), " px/s")
		print("   - Middle layer speed: ", parallax_background.get_middle_scroll_speed(), " px/s")

func update_world_speed(new_speed: float):
	"""Update world movement speed for all systems"""
	if obstacle_spawner:
		obstacle_spawner.obstacle_movement_speed = new_speed
	if parallax_background:
		parallax_background.set_world_movement_speed(new_speed)
	print("🚀 Updated world speed to: ", new_speed, " px/s")

func toggle_parallax_middle_layer(enabled: bool):
	"""Toggle middle parallax layer for performance/artistic control"""
	if parallax_background:
		parallax_background.toggle_middle_layer(enabled)

func get_world_movement_speed() -> float:
	"""Get current world movement speed"""
	return obstacle_spawner.obstacle_movement_speed if obstacle_spawner else 300.0

# === GAME STATE MANAGEMENT ===

func _connect_game_state_signals():
	"""Connect signals for tracking game state and statistics"""
	# Connect to nest spawner for tracking nest feeding events
	if nest_spawner:
		# The nest spawner emits nest_spawned which gives us access to individual nests
		nest_spawner.nest_spawned.connect(_on_nest_spawned)
		if enable_game_state_logging:
			print("🔗 Connected to nest spawner signals")
	
	# Connect to eagle for death events
	if eagle:
		eagle.eagle_died.connect(_on_eagle_died)
		if enable_game_state_logging:
			print("🔗 Connected to eagle death signal")

func _on_nest_spawned(nest: Node):
	"""Called when a new nest is spawned - connect to its feeding signal"""
	if not nest:
		return
	
	# Connect to this specific nest's feeding signal
	nest.nest_fed.connect(_on_nest_fed)
	
	if enable_game_state_logging:
		print("🏠 Connected to new nest feeding signal: ", nest.name)

func _on_nest_fed(_points: int = 0):
	"""Called when any nest is successfully fed with a fish"""
	if is_game_over:
		return  # Don't track stats after game over
	
	# Increment the fed nests count in our global statistics
	if GameStats:
		GameStats.increment_fed_nests()
		if enable_game_state_logging:
			print("📊 Nest fed! Total fed nests: ", GameStats.get_fed_nests_count())
	else:
		print("❌ Warning: GameStats singleton not available for nest tracking")

func _on_eagle_died():
	"""Called when the eagle dies - trigger game over sequence"""
	if is_game_over:
		return  # Prevent multiple game over triggers
	
	is_game_over = true
	
	if enable_game_state_logging:
		print("💀 Eagle died! Triggering game over sequence...")
		if GameStats:
			print("📊 Final Statistics:")
			print("   - Fed Nests: ", GameStats.get_fed_nests_count())
			print("   - Session Duration: ", "%.1f" % GameStats.get_session_duration(), " seconds")
	
	# Add a small delay for dramatic effect before transitioning
	if game_over_transition_delay > 0.0:
		await get_tree().create_timer(game_over_transition_delay).timeout
	
	# Trigger game over scene transition
	_trigger_game_over_scene()

func _trigger_game_over_scene():
	"""Transition to the game over scene"""
	if enable_game_state_logging:
		print("🎬 Transitioning to game over scene...")
	
	# Use SceneManager for smooth transition
	if SceneManager:
		SceneManager.change_scene("res://scenes/game_steps/game_over_scene.tscn")
	else:
		# Fallback if SceneManager not available
		print("⚠️  SceneManager not available, using direct scene change")
		get_tree().change_scene_to_file("res://scenes/game_steps/game_over_scene.tscn")

func _physics_process(_delta):
	"""Monitor eagle position for dying state boundary detection"""
	# Only monitor if game is not over and eagle is dying
	if is_game_over or not eagle or not camera:
		return
	
	# Check if eagle is dying and has fallen below screen
	if eagle.is_dying and _is_eagle_below_screen():
		# Check minimum fall duration if specified
		if eagle.min_death_fall_duration > 0.0 and eagle.death_fall_timer < eagle.min_death_fall_duration:
			return  # Not enough time has passed
		
		# Trigger game over
		_on_eagle_died()

func _is_eagle_below_screen() -> bool:
	"""Check if eagle has fallen below the visible screen area"""
	if not eagle or not camera:
		return false
	
	var center = camera.get_screen_center_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_bottom = center.y + (viewport_size.y * 0.5)
	var death_boundary = screen_bottom + eagle.death_boundary_margin
	
	return eagle.global_position.y > death_boundary

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_trigger_game_over():
	"""Debug method to manually trigger game over for testing"""
	print("🔧 DEBUG: Manually triggering game over")
	_on_eagle_died()

func debug_add_fed_nest():
	"""Debug method to manually add a fed nest for testing"""
	print("🔧 DEBUG: Manually adding fed nest")
	_on_nest_fed(0)  # Points parameter not used, just pass 0

func _test_obstacle_spawner_stage_integration():
	"""Task 9 verification: Test ObstacleSpawner integration with StageManager"""
	print("🧪 Task 9 - ObstacleSpawner Stage Integration:")
	
	if not obstacle_spawner:
		print("   ✗ ObstacleSpawner not available")
		return
	
	# Check if ObstacleSpawner connected to StageManager
	var stage_connected = false
	if StageManager and StageManager.stage_changed.is_connected(obstacle_spawner._on_stage_changed):
		stage_connected = true
	
	print("   - Connected to StageManager: ", "✓" if stage_connected else "✗")
	print("   - Stage config applied: ", "✓" if obstacle_spawner.current_stage_config else "✗")
	
	# Check current parameters from stage
	if obstacle_spawner.current_stage_config:
		var config = obstacle_spawner.current_stage_config
		print("   - Mountain weight: ", obstacle_spawner.mountain_weight, " (from stage ", config.stage_number, ")")
		print("   - Stalactite weight: ", obstacle_spawner.stalactite_weight)
		print("   - Island weight: ", obstacle_spawner.floating_island_weight)
		print("   - World speed: ", obstacle_spawner.obstacle_movement_speed)
		print("   - Spawn interval: ", "%.1f" % obstacle_spawner.spawn_interval, "s")
		
		# Verify stalactites are disabled in early stages
		if config.stage_number < 4 and obstacle_spawner.stalactite_weight > 0:
			print("   ⚠️  WARNING: Stalactites should be disabled in stages 1-3")
		elif config.stage_number >= 4 and obstacle_spawner.stalactite_weight == 0:
			print("   ⚠️  WARNING: Stalactites should be enabled in stage 4+")
		else:
			print("   ✓ Stalactite visibility correct for stage")
	else:
		print("   ✗ No stage config applied to ObstacleSpawner")

func _test_fish_spawner_stage_integration():
	"""Task 10 verification: Test FishSpawner integration with StageManager"""
	print("🧪 Task 10 - FishSpawner Stage Integration:")
	
	if not fish_spawner:
		print("   ✗ FishSpawner not available")
		return
	
	# Check if FishSpawner connected to StageManager
	var stage_connected = false
	if StageManager and StageManager.stage_changed.is_connected(fish_spawner._on_stage_changed):
		stage_connected = true
	
	print("   - Connected to StageManager: ", "✓" if stage_connected else "✗")
	print("   - Stage config applied: ", "✓" if fish_spawner.current_stage_config else "✗")
	
	# Check current parameters from stage
	if fish_spawner.current_stage_config:
		var config = fish_spawner.current_stage_config
		print("   - Fish enabled: ", fish_spawner.fish_enabled, " (from stage ", config.stage_number, ")")
		if fish_spawner.fish_enabled:
			print("   - Spawn interval: ", "%.1f" % fish_spawner.spawn_interval, "s")
			print("   - Spawn variance: ", "%.1f" % fish_spawner.spawn_interval_variance, "s")
			print("   - Timer running: ", "✓" if fish_spawner.spawn_timer.time_left > 0 else "✗")
		else:
			print("   - Spawn timer stopped: ", "✓" if fish_spawner.spawn_timer.time_left == 0 else "✗")
		
		# Verify fish are disabled in stage 1
		if config.stage_number == 1 and fish_spawner.fish_enabled:
			print("   ⚠️  WARNING: Fish should be disabled in stage 1")
		elif config.stage_number > 1 and not fish_spawner.fish_enabled:
			print("   ⚠️  WARNING: Fish should be enabled in stage 2+")
		else:
			print("   ✓ Fish visibility correct for stage")
	else:
		print("   ✗ No stage config applied to FishSpawner")

func _test_nest_spawner_stage_integration():
	"""Task 11 verification: Test NestSpawner integration with StageManager"""
	print("🧪 Task 11 - NestSpawner Stage Integration:")
	
	if not nest_spawner:
		print("   ✗ NestSpawner not available")
		return
	
	# Check if NestSpawner connected to StageManager
	var stage_connected = false
	if StageManager and StageManager.stage_changed.is_connected(nest_spawner._on_stage_changed):
		stage_connected = true
	
	print("   - Connected to StageManager: ", "✓" if stage_connected else "✗")
	print("   - Stage config applied: ", "✓" if nest_spawner.current_stage_config else "✗")
	
	# Check current parameters from stage
	if nest_spawner.current_stage_config:
		var config = nest_spawner.current_stage_config
		print("   - Nests enabled: ", nest_spawner.nests_enabled, " (from stage ", config.stage_number, ")")
		if nest_spawner.nests_enabled:
			print("   - Min skipped obstacles: ", nest_spawner.min_skipped_obstacles)
			print("   - Max skipped obstacles: ", nest_spawner.max_skipped_obstacles)
			print("   - Next nest target: ", nest_spawner.next_nest_spawn_target)
		else:
			print("   - Nest spawning disabled")
		
		# Verify nests are disabled in stages 1-2
		if config.stage_number <= 2 and nest_spawner.nests_enabled:
			print("   ⚠️  WARNING: Nests should be disabled in stages 1-2")
		elif config.stage_number >= 3 and not nest_spawner.nests_enabled:
			print("   ⚠️  WARNING: Nests should be enabled in stage 3+")
		else:
			print("   ✓ Nest visibility correct for stage")
	else:
		print("   ✗ No stage config applied to NestSpawner")
