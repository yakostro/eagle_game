extends Control

## Game Over Scene Controller
## Displays final game statistics and handles restart functionality
## Integrates with GameStats singleton and SceneManager for smooth transitions

# UI Component references using NodePath for flexibility
@export var game_over_label_path: NodePath = NodePath("UILayer/UIContainer/GameOverLabel")
@export var amount_label_path: NodePath = NodePath("UILayer/UIContainer/SavedNests/Amount")
@export var record_amount_label_path: NodePath = NodePath("UILayer/UIContainer/Record/Amount")
@export var new_record_label_path: NodePath = NodePath("UILayer/UIContainer/Amount2")
@export var restart_button_path: NodePath = NodePath("UILayer/UIContainer/RestartButton")
@export var background_music_path: NodePath = NodePath("AudioController/BackgroundMusic")

# Tweakable parameters for game balancing
@export var enable_keyboard_shortcuts: bool = true
@export var display_animation_duration: float = 0.5
@export var nest_text_format: String = "Saved %d Nests"
@export var no_nests_text: String = "No Nests Saved"
@export var single_nest_text: String = "Saved 1 Nest"

# UI Palette for consistent colors
@export var palette: UiPalette

# Component references
var game_over_label: Label
var saved_nests_label: Label
var amount_label: Label
var record_amount_label: Label
var new_record_label: Label
var restart_button: Button
var background_music: AudioStreamPlayer

# Scene state
var is_initialized: bool = false

func _ready():
	"""Initialize the game over scene with current statistics"""
	# Ensure palette is available (fallback to default resource if not assigned)
	if not palette:
		var default_palette := load("res://configs/ui/ui_palette_default.tres") as UiPalette
		if default_palette:
			palette = default_palette
	
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

func _get_ui_references():
	"""Get references to UI components using NodePaths"""
	game_over_label = get_node(game_over_label_path) if game_over_label_path else null
	amount_label = get_node(amount_label_path) if amount_label_path else null
	record_amount_label = get_node(record_amount_label_path) if record_amount_label_path else null
	new_record_label = get_node(new_record_label_path) if new_record_label_path else null
	restart_button = get_node(restart_button_path) if restart_button_path else null
	background_music = get_node(background_music_path) if background_music_path else null
	
	# Validate critical components (no print warnings for missing optional UI elements)

func _connect_signals():
	"""Connect UI signals for interaction handling"""
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Connect to GameStats for any real-time updates (future use)
	if GameStats:
		GameStats.stats_updated.connect(_on_stats_updated)
		GameStats.new_record_achieved.connect(_on_new_record_achieved)

func _initialize_statistics_display():
	"""Load and display current game statistics from GameStats singleton"""
	if not GameStats:
		return
	
	# Get current statistics
	var fed_nests_count = GameStats.get_fed_nests_count()
	
	# Check and update record if this session is a new record
	var is_new_record = GameStats.check_and_update_record()
	
	# Update the amount label with the nest count
	_update_amount_display(fed_nests_count)
	
	# Update the record display
	_update_record_display(GameStats.get_best_record())
	
	# Show new record indicator if applicable
	if is_new_record:
		_show_new_record_indicator()
	

func _update_amount_display(nests_count: int):
	"""Update the amount label with the saved nests count"""
	if not amount_label:
		return
	
	# Display format: "x [number]"
	amount_label.text = str(nests_count)

func _update_record_display(record_count: int):
	"""Update the record label with the best record count"""
	if not record_amount_label:
		return
	
	# Display the record amount
	record_amount_label.text = str(record_count)

func _show_new_record_indicator():
	"""Show the 'New Record!' indicator"""
	if not new_record_label:
		return
	
	# Make the new record label visible and set text
	new_record_label.visible = true
	new_record_label.text = "New record"
	
	# Use palette yellow for the achievement highlight
	new_record_label.modulate = (palette.Yellow3 if palette else Color.GOLD)
	


func _setup_input_handling():
	"""Set up keyboard shortcuts for accessibility"""
	if enable_keyboard_shortcuts:
		# Make sure this scene can receive input
		set_process_input(true)

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

# === BUTTON INTERACTION HANDLERS ===

func _on_restart_button_pressed():
	"""Handle restart button press"""
	_trigger_restart()

func _trigger_restart():
	"""Execute the restart sequence"""
	
	# Reset game statistics for new session
	if GameStats:
		GameStats.reset_session()
	
	# Reset stage system to stage 3 (skip tutorial stages)
	if StageManager:
		StageManager.skip_to_stage(3)
	
	# Use SceneManager for smooth transition to game scene
	if SceneManager:
		SceneManager.change_scene("res://scenes/game_steps/game.tscn")
	else:
		# Fallback if SceneManager not available
		get_tree().change_scene_to_file("res://scenes/game_steps/game.tscn")

# === SIGNAL HANDLERS ===

func _on_stats_updated(fed_nests: int):
	"""Handle real-time statistics updates (future use)"""
	# This would be called if stats change while on game over screen
	# Currently not needed, but ready for future enhancements
	_update_amount_display(fed_nests)

func _on_new_record_achieved(new_record: int):
	"""Handle new record achievement signal"""
	_update_record_display(new_record)
	_show_new_record_indicator()

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_set_nest_count(count: int):
	"""Debug method to test different nest counts"""
	_update_amount_display(count)

func debug_test_new_record():
	"""Debug method to test new record display"""
	_show_new_record_indicator()

func debug_print_scene_info():
	"""Debug method to get scene state information (no console output)"""
	pass
