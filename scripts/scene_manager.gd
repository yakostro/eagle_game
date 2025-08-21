extends Node

## Scene Manager - Global singleton for scene transitions
## Handles smooth transitions between all game scenes with fade effects
## Auto-loaded as singleton in project settings

signal scene_changing(from_scene: String, to_scene: String)
signal scene_changed(new_scene: String)

@export var transition_duration: float = 0.5
@export var fade_color: Color = Color.BLACK

var is_transitioning: bool = false
var transition_overlay: ColorRect

func _ready():
	# Create persistent transition overlay for scene changes
	_create_transition_overlay()
	
	# Note: We don't monitor tree_changed signal because it fires constantly 
	# during gameplay (spawning enemies, obstacles, particles, etc.)
	# Instead, we use our own scene_changing/scene_changed signals

func _create_transition_overlay():
	"""Create a fade overlay for smooth scene transitions"""
	transition_overlay = ColorRect.new()
	transition_overlay.color = fade_color
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.modulate.a = 0.0
	
	# Use highest layer so it's always on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 1000
	add_child(canvas_layer)
	canvas_layer.add_child(transition_overlay)
	
	# Make overlay cover the entire screen
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_scene(scene_path: String, transition_type: String = "fade") -> void:
	"""
	Change to a new scene with transition effect
	
	Args:
		scene_path: Path to the scene file (e.g., "res://scenes/game.tscn")
		transition_type: Type of transition ("fade", "instant")
	"""
	if is_transitioning:
		print("SceneManager: Already transitioning, ignoring request")
		return
		
	var current_scene_name = get_current_scene_name()
	scene_changing.emit(current_scene_name, scene_path)
	
	if transition_type == "instant":
		_change_scene_instant(scene_path)
	else:
		_change_scene_with_fade(scene_path)

func _change_scene_with_fade(scene_path: String) -> void:
	"""Perform scene change with fade transition"""
	is_transitioning = true
	
	# Fade out
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)
	await fade_out_tween.finished
	
	# Change scene while screen is black
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("SceneManager: Error changing scene to ", scene_path, " - Error code: ", error)
		is_transitioning = false
		return
	
	# Wait one frame for new scene to load
	await get_tree().process_frame
	
	# Fade in
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)
	await fade_in_tween.finished
	
	is_transitioning = false
	scene_changed.emit(get_current_scene_name())

func _change_scene_instant(scene_path: String) -> void:
	"""Perform instant scene change without transition"""
	is_transitioning = true
	
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("SceneManager: Error changing scene to ", scene_path, " - Error code: ", error)
	
	is_transitioning = false
	scene_changed.emit(get_current_scene_name())

func reload_current_scene() -> void:
	"""Reload the current scene with fade transition"""
	var current_scene_path = get_current_scene_path()
	if current_scene_path != "":
		change_scene(current_scene_path)
	else:
		print("SceneManager: Cannot reload - no valid current scene path")

func get_current_scene_name() -> String:
	"""Get the name of the current scene"""
	var tree = get_tree()
	if not tree:
		return "No Tree"
	
	var current_scene = tree.current_scene
	if current_scene:
		return current_scene.name
	return "Unknown"

func get_current_scene_path() -> String:
	"""Get the file path of the current scene"""
	var tree = get_tree()
	if not tree:
		return ""
	
	var current_scene = tree.current_scene
	if current_scene:
		return current_scene.scene_file_path
	return ""

# Debug functions for development
func debug_print_scene_info():
	"""Print debug information about current scene"""
	print("=== Scene Manager Debug Info ===")
	print("Current Scene: ", get_current_scene_name())
	print("Scene Path: ", get_current_scene_path())
	print("Is Transitioning: ", is_transitioning)
	print("Transition Duration: ", transition_duration)
	print("===============================")
