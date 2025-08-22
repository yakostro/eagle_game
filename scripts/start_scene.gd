extends Control

## Start Scene Controller
## Handles the entry point for "The Last Eagle" game
## Provides atmospheric introduction with universal input detection

signal start_game_requested

# Audio configuration - exposed to inspector for easy tweaking
@export_group("Audio Settings")
@export var background_music: AudioStream
@export var enable_background_music: bool = true
@export var music_volume: float = 0.3

# Input configuration
@export_group("Input Settings") 
@export var input_delay: float = 0.3  # Prevent accidental double-triggers
@export var show_input_feedback: bool = true

# Scene configuration
@export_group("Scene Settings")
@export var game_scene_path: String = "res://scenes/game.tscn"
@export var enable_fade_transition: bool = true

# UI configuration - using NodePath for flexible connection
@export_group("UI References")
@export var press_any_button_label_path: NodePath
@export var background_image_path: NodePath

# Internal state
var input_detected: bool = false
var audio_player: AudioStreamPlayer
var press_any_button_label: Label
var background_image: TextureRect

func _ready():
	print("StartScene: Initializing...")
	
	# Setup UI references
	_setup_ui_references()
	
	# Setup audio system
	_setup_audio()
	
	# Setup input detection
	_setup_input()
	
	# Start the scene
	_start_scene()

func _setup_ui_references():
	"""Connect to UI elements using NodePath exports"""
	if press_any_button_label_path:
		press_any_button_label = get_node(press_any_button_label_path)
		if press_any_button_label:
			print("StartScene: Connected to press any button label")
	
	if background_image_path:
		background_image = get_node(background_image_path)
		if background_image:
			print("StartScene: Connected to background image")

func _setup_audio():
	"""Initialize audio system for background music"""
	# Create audio player for background music
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Configure audio
	audio_player.volume_db = linear_to_db(music_volume)
	audio_player.bus = "Master"
	
	# Set background music if provided
	if background_music and enable_background_music:
		audio_player.stream = background_music
		audio_player.loop = true
		print("StartScene: Background music configured")

func _setup_input():
	"""Setup input detection system"""
	# Make sure this node can receive input
	set_process_unhandled_input(true)
	set_process_input(true)  # Also enable regular input for mouse handling
	print("StartScene: Input detection enabled")

func _start_scene():
	"""Initialize the start scene presentation"""
	# Play background music if enabled
	if enable_background_music and background_music and audio_player:
		audio_player.play()
		print("StartScene: Background music started")
	
	# Show welcome message
	print("StartScene: Ready - Waiting for player input")
	
	# Optional: Add fade-in effect for the scene
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _unhandled_input(event: InputEvent):
	"""
	Handle universal input detection
	Responds to keyboard keys and gamepad input
	"""
	# Ignore input if already detected or during scene transition
	if input_detected or SceneManager.is_transitioning:
		return
	
	var should_trigger = false
	
	# Check for keyboard input (any key press)
	if event is InputEventKey and event.pressed:
		should_trigger = true
		print("StartScene: Keyboard input detected - Key: ", event.keycode)
	
	# Check for gamepad input (any gamepad button)
	elif event is InputEventJoypadButton and event.pressed:
		should_trigger = true
		print("StartScene: Gamepad input detected - Button: ", event.button_index)
	
	# Trigger scene transition if valid input received
	if should_trigger:
		_handle_start_input()

func _handle_start_input():
	"""Process the start game input with delay protection"""
	if input_detected:
		return
		
	input_detected = true
	print("StartScene: Start game input received!")
	
	# Emit signal for other systems
	start_game_requested.emit()
	
	# Provide visual feedback if enabled
	if show_input_feedback and press_any_button_label:
		_show_input_feedback()
	
	# Add delay to prevent double-triggers
	await get_tree().create_timer(input_delay).timeout
	
	# Start scene transition
	_transition_to_game()

func _show_input_feedback():
	"""Provide visual feedback when input is detected"""
	if not press_any_button_label:
		return
		
	# Flash the label to show input was registered
	var original_modulate = press_any_button_label.modulate
	var feedback_tween = create_tween()
	feedback_tween.tween_property(press_any_button_label, "modulate", Color.WHITE * 1.5, 0.1)
	feedback_tween.tween_property(press_any_button_label, "modulate", original_modulate, 0.1)

func _transition_to_game():
	"""Handle transition to the main game scene"""
	print("StartScene: Transitioning to game scene: ", game_scene_path)
	
	# Stop background music with fade out
	if audio_player and audio_player.playing:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_method(_set_audio_volume, music_volume, 0.0, 0.3)
		await fade_out_tween.finished
		audio_player.stop()
	
	# Use SceneManager for smooth transition
	if enable_fade_transition:
		SceneManager.change_scene(game_scene_path, "fade")
	else:
		SceneManager.change_scene(game_scene_path, "instant")

func _set_audio_volume(volume: float):
	"""Helper function for smooth audio volume changes"""
	if audio_player:
		audio_player.volume_db = linear_to_db(volume)

func _input(event):
	"""Handle mouse input events"""
	# Handle mouse clicks (they don't reach _unhandled_input due to Control node consuming them)
	if event is InputEventMouseButton and event.pressed:
		if not input_detected and not SceneManager.is_transitioning:
			print("StartScene: Mouse input detected - Button: ", event.button_index)
			_handle_start_input()
			return

# Debug functions for development

func debug_trigger_start():
	"""Debug function to manually trigger scene start"""
	if OS.is_debug_build():
		print("StartScene Debug: Manual start triggered")
		_handle_start_input()

func _on_scene_manager_scene_changed(new_scene_name: String):
	"""Handle scene manager notifications"""
	print("StartScene: Scene changed to: ", new_scene_name)
