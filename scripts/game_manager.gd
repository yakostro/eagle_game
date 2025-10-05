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
@export var fade_foreground_path: NodePath
@export var esc_menu_path: NodePath

# Tweakable parameters for game over system
@export var game_over_transition_delay: float = 1.0  # Delay before transitioning to game over scene
@export var eagle_fall_timeout: float = 2.0  # Maximum time to wait for eagle to fall below screen
@export var enable_game_state_logging: bool = true
@export var run_stage_system_tests: bool = false

var obstacle_spawner: ObstacleSpawner
var parallax_background: ParallaxBackgroundSystem
var eagle: Eagle
var nest_spawner: NestSpawner
var fish_spawner: FishSpawner
var fade_foreground: FadeForeground
var esc_menu: UiEscMenu

# Game state tracking
var is_game_over: bool = false

# Screen boundary monitoring for dying eagle
var camera: Camera2D
var eagle_death_timer: float = 0.0  # Timer for eagle fall timeout

func _ready():
	
	# Get references to game systems
	obstacle_spawner = get_node(obstacle_spawner_path) if obstacle_spawner_path else null
	parallax_background = get_node(parallax_background_path) if parallax_background_path else null
	eagle = get_node(eagle_path) if eagle_path else null
	nest_spawner = get_node(nest_spawner_path) if nest_spawner_path else null
	fish_spawner = get_node(fish_spawner_path) if fish_spawner_path else null
	fade_foreground = get_node(fade_foreground_path) if fade_foreground_path else null
	esc_menu = get_node(esc_menu_path) if esc_menu_path else null
	
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
	if not fade_foreground:
		fade_foreground = find_child("FadeForeground", true, false)
	if not esc_menu:
		esc_menu = find_child("UiEscMenu", true, false)
	
	# Sync movement speeds
	sync_world_movement_speed()
	
	# Find camera for screen boundary detection
	camera = get_viewport().get_camera_2d()
	if not camera:
		camera = find_child("Camera2D", true, false)
	
	# Connect game state signals
	_connect_game_state_signals()
	
	# Activate the stage progression system now that game is ready
	_activate_stage_system()
		
	if run_stage_system_tests:
	
		# Task 9 verification: Check stage integration
		_test_obstacle_spawner_stage_integration()
		
		# Task 10 verification: Check fish spawner stage integration
		_test_fish_spawner_stage_integration()
		
		# Task 11 verification: Check nest spawner stage integration
		_test_nest_spawner_stage_integration()
		

		if StageManager:
						
			# Task 3 verification: Test stage configuration loading
			_test_stage_config_loading()
			
			# Task 4 verification: Test StageManager stage loading
			_test_stage_manager_loading()
			
			# Task 5 verification: Test stage progression
			_test_stage_progression()
			
			# Task 6 verification: Test all stage configurations
			_test_all_stage_configs()



func _on_stage_changed(_new_stage: int, _stage_config: StageConfiguration):
	"""Handle stage change events"""
	
	# Show completion requirement
	var _completion_text = ""
	if _stage_config.completion_type == StageConfiguration.CompletionType.TIMER:
		_completion_text = "Wait %.1f seconds" % _stage_config.completion_value
	else:
		_completion_text = "Spawn %d nests" % int(_stage_config.completion_value)

func _on_stage_completed(_completed_stage: int):
	"""Handle stage completion events"""

func _input(event):
	"""Handle testing input for stage progression"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:
			if StageManager:
				StageManager.force_advance_stage()
		elif event.keycode == KEY_R and not event.ctrl_pressed:
			if SceneManager:
				SceneManager.reload_current_scene()
			else:
				var error = get_tree().reload_current_scene()
				if error != OK:
					var path = get_tree().current_scene.scene_file_path
					if path != "":
						get_tree().change_scene_to_file(path)
		elif event.keycode == KEY_R and event.ctrl_pressed:
			if StageManager:
				StageManager.reset_stage_progress()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var stage_number = event.keycode - KEY_0
			if StageManager:
				StageManager.skip_to_stage(stage_number)
		elif event.keycode == KEY_A:
			# Direct auto-difficulty test key
			if StageManager:
				StageManager.force_trigger_auto_difficulty()
		elif event.keycode == KEY_F12:
			_toggle_fps_counter()

func _toggle_fps_counter():
	"""Toggle FPS counter visibility for debugging"""
	var fps_counter = get_node_or_null("CanvasLayer/FPSCounter")
	if fps_counter:
		fps_counter.toggle_visibility()
	else:
		push_warning("FPS Counter not found in CanvasLayer")

func sync_world_movement_speed():
	"""Synchronize world movement speed between systems"""
	if obstacle_spawner and parallax_background:
		var world_speed = obstacle_spawner.obstacle_movement_speed
		parallax_background.set_world_movement_speed(world_speed)
		

func update_world_speed(new_speed: float):
	"""Update world movement speed for all systems"""
	if obstacle_spawner:
		obstacle_spawner.obstacle_movement_speed = new_speed
	if parallax_background:
		parallax_background.set_world_movement_speed(new_speed)
	

func toggle_parallax_middle_layer(enabled: bool):
	"""Toggle middle parallax layer for performance/artistic control"""
	if parallax_background:
		parallax_background.toggle_middle_layer(enabled)

func get_world_movement_speed() -> float:
	"""Get current world movement speed"""
	return obstacle_spawner.obstacle_movement_speed if obstacle_spawner else 300.0

# === STAGE SYSTEM MANAGEMENT ===

func _activate_stage_system():
	"""Activate the stage progression system when game scene starts"""
	if not StageManager:
		push_error("GameManager: StageManager singleton not available!")
		return
	
	print("🚀 GameManager: Activating stage progression system...")
	StageManager.activate_stage_system()

# === GAME STATE MANAGEMENT ===

func _connect_game_state_signals():
	"""Connect signals for tracking game state and statistics"""
	# Connect to nest spawner for tracking nest feeding events
	if nest_spawner:
		# The nest spawner emits nest_spawned which gives us access to individual nests
		nest_spawner.nest_spawned.connect(_on_nest_spawned)
		pass # print removed
	
	# Connect to eagle for death events
	if eagle:
		eagle.eagle_died.connect(_on_eagle_died)
		pass # print removed

func _on_nest_spawned(nest: Node):
	"""Called when a new nest is spawned - connect to its feeding signal"""
	if not nest:
		return
	
	# Connect to this specific nest's feeding signal
	if not nest.nest_fed.is_connected(_on_nest_fed):
		nest.nest_fed.connect(_on_nest_fed)
	
	# Connect to this specific nest's missed signal
	if not nest.nest_missed.is_connected(_on_nest_missed):
		nest.nest_missed.connect(_on_nest_missed)
	
	# Connect nest signals to eagle for screech functionality
	if eagle:
		if not nest.nest_fed.is_connected(eagle.on_nest_fed):
			nest.nest_fed.connect(eagle.on_nest_fed)
		if not nest.nest_missed.is_connected(eagle.on_nest_missed):
			nest.nest_missed.connect(eagle.on_nest_missed)
	
	if enable_game_state_logging:
		pass # print removed

func _on_nest_fed(_points: int = 0):
	"""Called when any nest is successfully fed with a fish"""
	if is_game_over:
		return  # Don't track stats after game over
	
	# Increment the fed nests count in our global statistics
	if GameStats:
		GameStats.increment_fed_nests()
		pass # print removed	
	else:
		push_warning("GameManager: GameStats singleton not available for nest tracking")

func _on_nest_missed(_points: int = 0):
	"""Called when a nest goes off screen without being fed"""

	pass # print removed
	
	# Trigger fade foreground effect
	if fade_foreground:
		fade_foreground.show_fade_effect()

func _on_eagle_died():
	"""Called when the eagle dies - trigger game over sequence"""
	if is_game_over:
		return  # Prevent multiple game over triggers
	
	is_game_over = true
	eagle_death_timer = 0.0  # Reset death timer
	
	# Stop all spawning immediately to prevent obstacles from continuing to spawn
	_stop_all_spawning()
	
	# Deactivate stage progression when game ends
	if StageManager:
		StageManager.deactivate_stage_system()
	
	if enable_game_state_logging:
		pass # prints removed
		pass # prints removed
	
	# Add a small delay for dramatic effect before transitioning
	if game_over_transition_delay > 0.0:
		await get_tree().create_timer(game_over_transition_delay).timeout
	
	# Trigger game over scene transition
	_trigger_game_over_scene()
	
	# Emergency fallback: if we're still in this scene after 10 seconds, force transition
	await get_tree().create_timer(10.0).timeout
	if get_tree().current_scene.scene_file_path != "res://scenes/game_steps/game_over_scene.tscn":
		get_tree().change_scene_to_file("res://scenes/game_steps/game_over_scene.tscn")

func _stop_all_spawning():
	"""Stop all spawners to prevent continued spawning during game over"""
	# Stop obstacle spawner by disabling its processing
	if obstacle_spawner:
		obstacle_spawner.set_process(false)
	
	# Stop fish spawner by stopping its timer
	if fish_spawner and fish_spawner.spawn_timer:
		fish_spawner.spawn_timer.stop()
	
	# Stop any boost timer in fish spawner
	if fish_spawner and fish_spawner.boost_timer:
		fish_spawner.boost_timer.stop()

func _trigger_game_over_scene():
	"""Transition to the game over scene"""

	
	# Use SceneManager for smooth transition
	if SceneManager:
		# Check if SceneManager is already transitioning
		if SceneManager.is_transitioning:
			await SceneManager.scene_changed
		
		SceneManager.change_scene("res://scenes/game_steps/game_over_scene.tscn")
		
		# Wait for the transition to complete or timeout after 5 seconds
		var timeout_timer = get_tree().create_timer(5.0)
		var transition_completed = false
		
		# Connect to scene_changed signal to track completion
		var scene_change_handler = func(_new_scene_name: String): 
			transition_completed = true
		SceneManager.scene_changed.connect(scene_change_handler, CONNECT_ONE_SHOT)
		
		# Wait for either timeout or scene change
		await timeout_timer.timeout
		
		if not transition_completed:
			SceneManager.scene_changed.disconnect(scene_change_handler)
			get_tree().change_scene_to_file("res://scenes/game_steps/game_over_scene.tscn")

	else:
		# Fallback if SceneManager not available
		get_tree().change_scene_to_file("res://scenes/game_steps/game_over_scene.tscn")

func _physics_process(delta):
	"""Monitor eagle position for dying state boundary detection"""
	# Only monitor if game is not over and eagle is dying
	if is_game_over or not eagle or not camera:
		return
	
	# Start timing when eagle enters dying state
	if eagle.is_dying:
		eagle_death_timer += delta
		
		# Check if eagle has fallen below screen
		if _is_eagle_below_screen():
			# Check minimum fall duration if specified
			if eagle.min_death_fall_duration > 0.0 and eagle.death_fall_timer < eagle.min_death_fall_duration:
				return  # Not enough time has passed
			
			# Eagle fell below screen - trigger game over
			_on_eagle_died()

		elif eagle_death_timer >= eagle_fall_timeout:
			# Timeout reached - force game over even if eagle hasn't fallen below screen
			_on_eagle_died()
	else:
		# Reset timer when eagle is not dying
		eagle_death_timer = 0.0

func _is_eagle_below_screen() -> bool:
	"""Check if eagle has fallen below the visible screen area"""
	if not eagle or not camera:
		return false
	
	var center = camera.get_screen_center_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_bottom = center.y + (viewport_size.y * 0.5)
	var death_boundary = screen_bottom + eagle.death_boundary_margin
	
	return eagle.global_position.y > death_boundary

# === GAME RESTART ===

func restart_game():
	"""Restart the game from the beginning - can be called from pause menu or other systems"""
	# Step 1: Unpause the game (important if called from pause menu)
	get_tree().paused = false
	
	# Step 2: Reset game state flags
	is_game_over = false
	
	# Step 3: Reset GameStats if available
	if GameStats:
		GameStats.reset_stats()
	
	# Step 4: Reset StageManager to stage 1 if available
	if StageManager:
		StageManager.reset_stage_progress()
	
	# Step 5: Reload the current scene
	if SceneManager:
		SceneManager.reload_current_scene()
	else:
		# Fallback if SceneManager not available
		var error = get_tree().reload_current_scene()
		if error != OK:
			var path = get_tree().current_scene.scene_file_path
			if path != "":
				get_tree().change_scene_to_file(path)

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_trigger_game_over():
	"""Debug method to manually trigger game over for testing"""
	
	_on_eagle_died()

func debug_add_fed_nest():
	"""Debug method to manually add a fed nest for testing"""
	
	_on_nest_fed(0)  # Points parameter not used, just pass 0

func _test_obstacle_spawner_stage_integration():
	"""Task 9 verification: Test ObstacleSpawner integration with StageManager"""
	
	
	if not obstacle_spawner:
		
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
	
	
	if not fish_spawner:
		
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
	
	
	if not nest_spawner:
		
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
		pass # No stage config applied to NestSpawner

func _test_stage_config_loading():
	"""Test loading Stage 1 configuration (Task 3 verification)"""
	
	
	var stage_01_path = "res://scenes/configs/stages/stage_01_introduction.tres"
	var stage_config = load(stage_01_path) as StageConfiguration
	
	if stage_config:
		
		
		
		
		
		
		
		if stage_config.validate_parameters():
			pass # validation print removed
		else:
			pass # validation print removed
	else:
		pass # Stage 1 config loads print removed

func _test_stage_manager_loading():
	"""Test StageManager stage loading functionality (Task 4 verification)"""
	
	
	if not StageManager:
		
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
			pass # print removed
		else:
			pass # print removed
		
		# Test loading of non-existent stage (should fail gracefully)
		if not StageManager.load_stage(99):
			pass # print removed
		else:
			pass # print removed
		
	else:
		pass # print removed

func _test_stage_progression():
	"""Test StageManager stage progression functionality (Task 5 verification)"""
	
	
	if not StageManager:
		
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
			pass # print removed
		else:
			pass # print removed

		if not StageManager.stage_completed.is_connected(_on_stage_completed):
			StageManager.stage_completed.connect(_on_stage_completed)
			pass # print removed
		else:
			pass # print removed
	
	
	
	
	
	print("   - Progression test will run during gameplay")
	print("   - Press P to force advance stage (testing)")
	print("   - Press 1-6 to skip to specific stage (testing)")  
	print("   - Press Ctrl+R to reset stage progress (testing)")
	
	# Task 7: Start comprehensive stage system test
	_start_stage_system_test()

func _test_all_stage_configs():
	"""Test loading all stage configuration files (Task 6 verification)"""
	
	
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
			
			
			
			
			
			
			
			# Check progression logic
			if config.world_speed <= previous_speed and stage_number > 1:
				push_warning("GameManager: Speed didn't increase from previous stage in stage %d!" % stage_number)
			
			if not config.validate_parameters():
				push_error("GameManager: Parameter validation failed for stage %d!" % stage_number)
			
			previous_speed = config.world_speed
		else:
			push_error("GameManager: Failed to load stage %d: %s" % [stage_number, stage_files[i]])
	
	pass # Summary print removed	
	if loaded_count == 6:
		pass # All stage configurations ready for progression testing print removed
	else:
		pass # Some stage configurations are missing or invalid print removed

func _start_stage_system_test():
	"""Start comprehensive stage system testing (Task 7)"""
	
	
	
	if not StageManager:
		push_error("GameManager: CRITICAL: StageManager not available!")
		return
	
	# Test 1: Verify current stage is loaded
	var current_config = StageManager.get_current_stage_config()
	if current_config:
		pass # prints removed
		pass # prints removed
		pass # prints removed
		pass # prints removed
	else:
		push_error("GameManager: No stage configuration loaded!")
		return
	
	# Test 2: Quick parameter progression verification
	
	_verify_parameter_progression()
	
	# Test 3: Test stage 6 limit  
	
	_test_stage_six_limit()

func _verify_parameter_progression():
	"""Verify parameters change correctly between stages"""
	var stage_1 = load("res://scenes/configs/stages/stage_01_introduction.tres") as StageConfiguration
	var stage_6 = load("res://scenes/configs/stages/stage_06_final.tres") as StageConfiguration
	
	if not stage_1 or not stage_6:
		push_error("GameManager: Could not load stage configs for comparison")
		return
	
	# Check key progressions
	var _speed_progression = stage_6.world_speed > stage_1.world_speed
	var _stalactites_added = stage_6.stalactite_weight > stage_1.stalactite_weight  
	var _nests_enabled = not stage_1.nests_enabled and stage_6.nests_enabled
	var _fish_enabled = not stage_1.fish_enabled and stage_6.fish_enabled
	
	pass # prints removed
	pass # prints removed
	pass # prints removed
	pass # prints removed

func _test_stage_six_limit():
	"""Test that stage 6 doesn't advance to stage 7"""
	var original_stage = StageManager.current_stage
	var original_auto_difficulty = StageManager.auto_difficulty_enabled
	
	# Skip to stage 6
	if StageManager.skip_to_stage(6):
		pass # print removed
		
		# Try to advance beyond stage 6
		StageManager.force_advance_stage()
		
		# Check if auto-difficulty was enabled instead of advancing to stage 7
		if StageManager.auto_difficulty_enabled and not original_auto_difficulty:
			pass # auto-difficulty enabled print removed
		else:
			push_error("GameManager: Stage 6→7 limit test: ❌")
		
		# Reset to original state
		StageManager.disable_auto_difficulty()
		StageManager.skip_to_stage(original_stage)
		pass # print removed
		
	else:
		push_error("GameManager: Failed to skip to stage 6: ❌")
