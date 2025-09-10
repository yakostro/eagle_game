extends Control

## Intro Scene Controller
## Displays two labels sequentially before transitioning to game scene
## Shows company/studio name, then game title with configurable delays

signal intro_completed

# Animation configuration - exposed to inspector for easy tweaking
@export_group("Animation Settings")
@export var first_label_delay: float = 1.0  # Delay before first label appears
@export var second_label_delay: float = 2.0  # Delay before second label appears  
@export var label_fade_duration: float = 0.8  # Duration for label fade in/out
@export var total_scene_duration: float = 5.0  # Total time before transitioning to game

# Scene configuration
@export_group("Scene Settings")
@export var game_scene_path: String = "res://scenes/game_steps/game.tscn"
@export var enable_skip_input: bool = true  # Allow skipping with any input

# Audio configuration - exposed to inspector for easy tweaking
@export_group("Audio Settings")
@export var intro_music: AudioStream
@export var enable_intro_music: bool = true
@export var music_volume: float = 0.4
@export var audio_fade_duration: float = 0.5

# UI References - using NodePath for flexible connection
@export_group("UI References")
@export var first_label_path: NodePath  # First label to show (e.g., studio name)
@export var second_label_path: NodePath  # Second label to show (e.g., game title)
@export var background_path: NodePath  # Optional background element
@export var intro_music_path: NodePath = NodePath("AudioController/IntroMusic")  # Audio player for intro music

# Internal state
var first_label: Label
var second_label: Label
var background_element: Control
var intro_music_player: AudioStreamPlayer
var intro_tween: Tween
var input_detected: bool = false
var is_playing: bool = false

func _ready():
	print("IntroScene: Initializing...")
	
	# Setup UI references
	_setup_ui_references()
	
	# Setup audio system
	_setup_audio()
	
	# Setup input detection for skipping
	if enable_skip_input:
		_setup_input()
	
	# Start the intro sequence
	_start_intro_sequence()

func _setup_ui_references():
	"""Connect to UI elements using NodePath exports"""
	if first_label_path:
		first_label = get_node(first_label_path)
		if first_label:
			print("IntroScene: Connected to first label")
			# Start labels as invisible
			first_label.modulate.a = 0.0
		else:
			print("IntroScene: Warning - First label not found at path: ", first_label_path)
	
	if second_label_path:
		second_label = get_node(second_label_path)
		if second_label:
			print("IntroScene: Connected to second label")
			# Start labels as invisible
			second_label.modulate.a = 0.0
		else:
			print("IntroScene: Warning - Second label not found at path: ", second_label_path)
	
	if background_path:
		background_element = get_node(background_path)
		if background_element:
			print("IntroScene: Connected to background element")
	
	if intro_music_path:
		intro_music_player = get_node(intro_music_path)
		if intro_music_player:
			print("IntroScene: Connected to intro music player")
		else:
			print("IntroScene: Warning - Intro music player not found at path: ", intro_music_path)

func _setup_audio():
	"""Initialize audio system for intro music"""
	if not intro_music_player:
		return
	
	# Configure audio
	intro_music_player.volume_db = linear_to_db(music_volume)
	intro_music_player.bus = "Master"
	
	# Set intro music if provided
	if intro_music and enable_intro_music:
		intro_music_player.stream = intro_music
		print("IntroScene: Intro music configured")
		print("IntroScene: Audio volume set to ", music_volume, " (db: ", intro_music_player.volume_db, ")")

func _setup_input():
	"""Setup input detection for skipping intro"""
	set_process_unhandled_input(true)
	set_process_input(true)  # Also enable regular input for mouse handling
	print("IntroScene: Input detection enabled for skipping")

func _start_intro_sequence():
	"""Start the main intro animation sequence"""
	if is_playing:
		return
		
	is_playing = true
	print("IntroScene: Starting intro sequence...")
	
	# Start intro music if enabled
	if enable_intro_music and intro_music and intro_music_player:
		intro_music_player.play()
		print("IntroScene: Intro music started")
	
	# Create main tween for the entire sequence
	intro_tween = create_tween()
	
	# Sequence timeline:
	# 1. Wait for first_label_delay
	# 2. Fade in first label
	# 3. Wait for second_label_delay  
	# 4. Fade in second label
	# 5. Wait for remaining time
	# 6. Transition to game scene
	
	# Phase 1: Initial delay
	intro_tween.tween_interval(first_label_delay)
	intro_tween.tween_callback(_show_first_label)
	
	# Phase 2: Wait then show second label
	intro_tween.tween_interval(second_label_delay)
	intro_tween.tween_callback(_show_second_label)
	
	# Phase 3: Wait for remaining time then transition
	var remaining_time = total_scene_duration - first_label_delay - second_label_delay
	if remaining_time > 0:
		intro_tween.tween_interval(remaining_time)
	
	intro_tween.tween_callback(_complete_intro)

func _show_first_label():
	"""Animate the first label appearing"""
	if not first_label or input_detected:
		return
		
	print("IntroScene: Showing first label")
	
	# Fade in the first label
	var fade_tween = create_tween()
	fade_tween.tween_property(first_label, "modulate:a", 1.0, label_fade_duration)

func _show_second_label():
	"""Animate the second label appearing"""
	if not second_label or input_detected:
		return
		
	print("IntroScene: Showing second label")
	
	# Fade in the second label
	var fade_tween = create_tween()
	fade_tween.tween_property(second_label, "modulate:a", 1.0, label_fade_duration)

func _complete_intro():
	"""Complete the intro sequence and transition to game"""
	if input_detected:
		return
		
	print("IntroScene: Intro sequence completed, transitioning to game")
	intro_completed.emit()
	_transition_to_game()

func _skip_intro():
	"""Skip the intro sequence and transition immediately"""
	if input_detected or not is_playing:
		return
		
	input_detected = true
	print("IntroScene: Intro skipped by user input")
	
	# Stop current tween
	if intro_tween:
		intro_tween.kill()
	
	# Show both labels immediately if they exist
	if first_label:
		first_label.modulate.a = 1.0
	if second_label:
		second_label.modulate.a = 1.0
	
	# Brief delay then transition
	await get_tree().create_timer(0.3).timeout
	intro_completed.emit()
	_transition_to_game()

func _transition_to_game():
	"""Handle transition to the main game scene"""
	print("IntroScene: Transitioning to game scene: ", game_scene_path)
	
	# Stop intro music with fade out
	if intro_music_player and intro_music_player.playing:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_method(_set_audio_volume, music_volume, 0.0, audio_fade_duration)
		await fade_out_tween.finished
		intro_music_player.stop()
		print("IntroScene: Intro music faded out and stopped")
	
	# Use SceneManager for smooth transition
	SceneManager.change_scene(game_scene_path, "fade")

func _unhandled_input(event: InputEvent):
	"""Handle input for skipping intro"""
	if not enable_skip_input or input_detected or SceneManager.is_transitioning:
		return
	
	var should_skip = false
	
	# Check for keyboard input (any key press)
	if event is InputEventKey and event.pressed:
		should_skip = true
		print("IntroScene: Skip triggered by keyboard - Key: ", event.keycode)
	
	# Check for gamepad input (any gamepad button)
	elif event is InputEventJoypadButton and event.pressed:
		should_skip = true
		print("IntroScene: Skip triggered by gamepad - Button: ", event.button_index)
	
	if should_skip:
		_skip_intro()

func _input(event):
	"""Handle mouse input events for skipping"""
	if not enable_skip_input or input_detected or SceneManager.is_transitioning:
		return
		
	# Handle mouse clicks
	if event is InputEventMouseButton and event.pressed:
		print("IntroScene: Skip triggered by mouse - Button: ", event.button_index)
		_skip_intro()

# Debug functions for development
func debug_skip_intro():
	"""Debug function to manually skip intro"""
	if OS.is_debug_build():
		print("IntroScene Debug: Manual skip triggered")
		_skip_intro()

func debug_restart_intro():
	"""Debug function to restart intro sequence"""
	if OS.is_debug_build():
		print("IntroScene Debug: Restarting intro sequence")
		input_detected = false
		is_playing = false
		if first_label:
			first_label.modulate.a = 0.0
		if second_label:
			second_label.modulate.a = 0.0
		_start_intro_sequence()

func _set_audio_volume(volume: float):
	"""Helper function for smooth audio volume changes"""
	if intro_music_player:
		intro_music_player.volume_db = linear_to_db(volume)
