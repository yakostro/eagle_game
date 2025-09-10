extends Control

## Game Over Scene Controller
## Displays final game statistics and handles restart functionality
## Integrates with GameStats singleton and SceneManager for smooth transitions

# UI Component references using NodePath for flexibility
@export var game_over_label_path: NodePath = NodePath("UILayer/UIContainer/GameOverLabel")
@export var saved_nests_label_path: NodePath = NodePath("UILayer/UIContainer/StatsContainer/SavedNestsLabel")
@export var restart_button_path: NodePath = NodePath("UILayer/UIContainer/RestartButton")
@export var background_music_path: NodePath = NodePath("AudioController/BackgroundMusic")

# Tweakable parameters for game balancing
@export var enable_keyboard_shortcuts: bool = true
@export var display_animation_duration: float = 0.5
@export var nest_text_format: String = "Saved %d Nests"
@export var no_nests_text: String = "No Nests Saved"
@export var single_nest_text: String = "Saved 1 Nest"

# Component references
var game_over_label: Label
var saved_nests_label: Label
var restart_button: Button
var background_music: AudioStreamPlayer

# Scene state
var is_initialized: bool = false

func _ready():
	"""Initialize the game over scene with current statistics"""
	print("🎬 Game Over Scene initializing...")
	
	# Get references to UI components
	_get_ui_references()
	
	# Connect button signals
	_connect_signals()
	
	# Load and display current game statistics
	_initialize_statistics_display()
	
	# Set up input handling
	_setup_input_handling()
	
	# Optional: Play initialization animation
	_play_entrance_animation()
	
	is_initialized = true
	print("✅ Game Over Scene fully initialized")

func _get_ui_references():
	"""Get references to UI components using NodePaths"""
	game_over_label = get_node(game_over_label_path) if game_over_label_path else null
	saved_nests_label = get_node(saved_nests_label_path) if saved_nests_label_path else null
	restart_button = get_node(restart_button_path) if restart_button_path else null
	background_music = get_node(background_music_path) if background_music_path else null
	
	# Validate critical components
	if not game_over_label:
		print("❌ Warning: Game Over Label not found at path: ", game_over_label_path)
	if not saved_nests_label:
		print("❌ Warning: Saved Nests Label not found at path: ", saved_nests_label_path)
	if not restart_button:
		print("❌ Warning: Restart Button not found at path: ", restart_button_path)

func _connect_signals():
	"""Connect UI signals for interaction handling"""
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
		print("🔗 Connected restart button signal")
	
	# Connect to GameStats for any real-time updates (future use)
	if GameStats:
		GameStats.stats_updated.connect(_on_stats_updated)
		print("🔗 Connected to GameStats signals")

func _initialize_statistics_display():
	"""Load and display current game statistics from GameStats singleton"""
	if not GameStats:
		print("❌ Error: GameStats singleton not available!")
		return
	
	# Get current statistics
	var fed_nests_count = GameStats.get_fed_nests_count()
	
	# Update the saved nests display
	_update_saved_nests_display(fed_nests_count)
	
	print("📊 Displayed statistics - Fed Nests: ", fed_nests_count)

func _update_saved_nests_display(nests_count: int):
	"""Update the saved nests label with proper grammar"""
	if not saved_nests_label:
		return
	
	var display_text: String
	
	# Handle different cases for better user experience
	if nests_count == 0:
		display_text = no_nests_text
		saved_nests_label.modulate = Color.GRAY  # Dimmed for no achievement
	elif nests_count == 1:
		display_text = single_nest_text
		saved_nests_label.modulate = Color.WHITE
	else:
		display_text = nest_text_format % nests_count
		saved_nests_label.modulate = Color.WHITE
		
		# Special highlighting for high achievements (future enhancement)
		if nests_count >= 10:
			saved_nests_label.modulate = Color.GOLD
	
	saved_nests_label.text = display_text
	print("🏠 Updated nest display: '", display_text, "'")

func _setup_input_handling():
	"""Set up keyboard shortcuts for accessibility"""
	if enable_keyboard_shortcuts:
		# Make sure this scene can receive input
		set_process_input(true)
		print("⌨️  Keyboard shortcuts enabled (Space/Enter for restart)")

func _input(event):
	"""Handle keyboard input for quick actions"""
	if not is_initialized or not enable_keyboard_shortcuts:
		return
	
	# Handle restart shortcuts
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# ui_accept = Enter, ui_select = Space
		_trigger_restart()
		get_viewport().set_input_as_handled()

func _play_entrance_animation():
	"""Optional entrance animation for polish (future enhancement)"""
	if display_animation_duration <= 0.0:
		return
	
	# Simple fade-in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, display_animation_duration)
	print("🎭 Playing entrance fade-in animation")

# === BUTTON INTERACTION HANDLERS ===

func _on_restart_button_pressed():
	"""Handle restart button press"""
	print("🔄 Restart button pressed!")
	_trigger_restart()

func _trigger_restart():
	"""Execute the restart sequence"""
	print("🚀 Triggering game restart sequence...")
	
	# Reset game statistics for new session
	if GameStats:
		GameStats.reset_session()
		print("📊 Game statistics reset for new session")
	
	# Reset stage system to stage 1
	if StageManager:
		StageManager.reset_to_stage_one()
		print("🎯 Stage reset to 1 for new run")
	
	# Use SceneManager for smooth transition to game scene
	if SceneManager:
		SceneManager.change_scene("res://scenes/game_steps/game.tscn")
		print("🎬 Transitioning to game scene")
	else:
		# Fallback if SceneManager not available
		print("⚠️  SceneManager not available, using direct scene change")
		get_tree().change_scene_to_file("res://scenes/game_steps/game.tscn")

# === SIGNAL HANDLERS ===

func _on_stats_updated(fed_nests: int):
	"""Handle real-time statistics updates (future use)"""
	# This would be called if stats change while on game over screen
	# Currently not needed, but ready for future enhancements
	_update_saved_nests_display(fed_nests)

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_set_nest_count(count: int):
	"""Debug method to test different nest counts"""
	print("🔧 DEBUG: Setting nest count to ", count)
	_update_saved_nests_display(count)

func debug_print_scene_info():
	"""Print debug information about the scene state"""
	print("=== Game Over Scene Debug Info ===")
	print("Initialized: ", is_initialized)
	print("Keyboard Shortcuts: ", enable_keyboard_shortcuts)
	print("GameStats Available: ", GameStats != null)
	print("SceneManager Available: ", SceneManager != null)
	if GameStats:
		print("Current Fed Nests: ", GameStats.get_fed_nests_count())
	print("===================================")
