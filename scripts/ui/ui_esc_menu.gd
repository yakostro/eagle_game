extends Node2D
class_name UiEscMenu

## ESC Menu & Pause System
## Handles pausing the game, showing menu overlay, and menu actions

# Export variables for tweaking
@export var fade_duration: float = 0.2
@export var overlay_opacity: float = 0.7
@export var overlay_color: Color = Color(0.06, 0, 0.07, 1.0)

# Node references
@export var fade_overlay_path: NodePath = "UILayer/UIContainer/FadeOverlay"
@export var resume_button_path: NodePath = "UILayer/UIContainer/VBoxContainer/Resume"
@export var restart_button_path: NodePath = "UILayer/UIContainer/VBoxContainer/Restart"
@export var quit_button_path: NodePath = "UILayer/UIContainer/VBoxContainer/Quit"
@export var game_manager_path: NodePath

var ui_layer: CanvasLayer
var fade_overlay: ColorRect
var resume_button: Button
var restart_button: Button
var quit_button: Button
var game_manager: GameManager

# State tracking
var is_menu_visible: bool = false
var is_animating: bool = false
var current_tween: Tween
var original_layer: int = 10

func _ready():
	# Set process mode to always work during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get UILayer reference
	ui_layer = find_child("UILayer", true, false)
	if not ui_layer:
		push_error("UiEscMenu: UILayer not found!")
		return
	
	# Store original layer
	original_layer = ui_layer.layer
	
	# Get node references - try NodePath first, then auto-find
	if fade_overlay_path and not fade_overlay_path.is_empty():
		fade_overlay = get_node(fade_overlay_path)
	else:
		fade_overlay = find_child("FadeOverlay", true, false)
	
	if resume_button_path and not resume_button_path.is_empty():
		resume_button = get_node(resume_button_path)
	else:
		resume_button = find_child("Resume", true, false)
	
	if restart_button_path and not restart_button_path.is_empty():
		restart_button = get_node(restart_button_path)
	else:
		restart_button = find_child("Restart", true, false)
	
	if quit_button_path and not quit_button_path.is_empty():
		quit_button = get_node(quit_button_path)
	else:
		quit_button = find_child("Quit", true, false)
	
	# Find GameManager
	if game_manager_path and not game_manager_path.is_empty():
		game_manager = get_node(game_manager_path)
	else:
		game_manager = get_tree().current_scene.find_child("GameManager", true, false)
	
	# Setup overlay color
	if fade_overlay:
		fade_overlay.color = overlay_color
		fade_overlay.modulate.a = 0.0
	
	# Connect button signals
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	else:
		push_warning("UiEscMenu: Resume button not found!")
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	else:
		push_warning("UiEscMenu: Restart button not found!")
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		push_warning("UiEscMenu: Quit button not found!")
	
	# Initially hide the menu by hiding the UILayer
	ui_layer.visible = false
	is_menu_visible = false

func _input(event):
	"""Handle ESC key input"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Don't allow ESC during animation
		if is_animating:
			return
		
		# Don't allow ESC if game is over
		if game_manager and game_manager.is_game_over:
			return
		
		# Toggle menu
		if is_menu_visible:
			hide_menu()
		else:
			show_menu()
		
		# Consume the input
		get_viewport().set_input_as_handled()

func show_menu():
	"""Show the pause menu with fade animation"""
	if is_menu_visible or is_animating or not ui_layer:
		return
	
	is_animating = true
	is_menu_visible = true
	
	# Pause the game
	get_tree().paused = true
	
	# Set layer to be on top of everything (higher than main UI layer 20)
	ui_layer.layer = 100
	
	# Make menu visible
	ui_layer.visible = true
	
	# Animate fade in
	_animate_fade(0.0, 1.0, func(): 
		is_animating = false
	)

func hide_menu():
	"""Hide the pause menu with fade animation"""
	if not is_menu_visible or is_animating or not ui_layer:
		return
	
	is_animating = true
	is_menu_visible = false
	
	# Unpause the game
	get_tree().paused = false
	
	# Animate fade out
	_animate_fade(1.0, 0.0, func():
		ui_layer.visible = false
		# Restore original layer
		ui_layer.layer = original_layer
		is_animating = false
	)

func _animate_fade(from_alpha: float, to_alpha: float, on_complete: Callable):
	"""Animate the fade overlay alpha"""
	# Clean up existing tween
	if current_tween and is_instance_valid(current_tween):
		current_tween.kill()
	
	if not fade_overlay:
		on_complete.call()
		return
	
	# Create new tween
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_CUBIC)
	current_tween.set_ease(Tween.EASE_OUT)
	
	# Tween the alpha
	current_tween.tween_property(fade_overlay, "modulate:a", to_alpha, fade_duration).from(from_alpha)
	
	# Call completion callback
	current_tween.tween_callback(on_complete)

func _on_resume_pressed():
	"""Handle Resume button press"""
	hide_menu()

func _on_restart_pressed():
	"""Handle Restart button press"""
	# Hide menu first (will unpause)
	is_animating = false
	is_menu_visible = false
	if ui_layer:
		ui_layer.visible = false
		ui_layer.layer = original_layer
	
	# Call GameManager restart function
	if game_manager:
		game_manager.restart_game()
	else:
		# Fallback if GameManager not found
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_quit_pressed():
	"""Handle Quit button press"""
	get_tree().quit()

func _exit_tree():
	"""Cleanup when node is removed"""
	# Make sure game is unpaused if menu is removed
	if is_menu_visible:
		get_tree().paused = false
	
	# Clean up tween
	if current_tween and is_instance_valid(current_tween):
		current_tween.kill()
