extends Control
class_name FadeForeground

## Fade foreground effect that shows when eagle misses a nest
## Displays a sprite that fades in, stays visible, then fades out

# Export variables for tweaking timing
@export var fade_in_duration: float = 0.5
@export var visible_duration: float = 1.0  
@export var fade_out_duration: float = 0.8
@export var fade_sprite_path: NodePath = "FadeSprite"

@onready var fade_sprite: TextureRect = get_node(fade_sprite_path)

var is_playing_effect: bool = false
var current_tween: Tween

func _ready():
	# Initially hidden
	hide_immediately()
	
	# Connect to tree exiting signal for cleanup
	tree_exiting.connect(_cleanup_tween)

func show_fade_effect():
	"""Trigger the complete fade in -> visible -> fade out sequence"""
	if is_playing_effect:
		return  # Don't interrupt ongoing effect
	
	# Clean up any existing tween first
	_cleanup_tween()
	
	is_playing_effect = true
	
	# Make sure we're visible as a Control but sprite starts transparent
	visible = true
	if fade_sprite:
		fade_sprite.modulate.a = 0.0
	
	# Create tween for the complete sequence
	current_tween = create_tween()
	
	# Make sure tween is properly configured
	if current_tween:
		# Phase 1: Fade in
		current_tween.tween_method(_set_fade_alpha, 0.0, 1.0, fade_in_duration)
		
		# Phase 2: Stay visible
		current_tween.tween_interval(visible_duration)
		
		# Phase 3: Fade out
		current_tween.tween_method(_set_fade_alpha, 1.0, 0.0, fade_out_duration)
		
		# When complete, hide and reset
		current_tween.tween_callback(_on_fade_complete)
		
		# Connect to tween finished signal as backup
		current_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)
	else:
		# Fallback if tween creation failed
		_on_fade_complete()

func _set_fade_alpha(alpha: float):
	"""Helper method to set the fade sprite's alpha"""
	if fade_sprite:
		fade_sprite.modulate.a = alpha

func _on_fade_complete():
	"""Called when the entire fade effect is complete"""
	_cleanup_tween()
	hide_immediately()

func _on_tween_finished():
	"""Backup method called when tween finishes (in case callback fails)"""
	if is_playing_effect:
		_on_fade_complete()

func _cleanup_tween():
	"""Clean up the current tween safely"""
	if current_tween and is_instance_valid(current_tween):
		current_tween.kill()
	current_tween = null

func hide_immediately():
	"""Immediately hide the fade effect"""
	_cleanup_tween()
	visible = false
	if fade_sprite:
		fade_sprite.modulate.a = 0.0
	is_playing_effect = false

func is_effect_playing() -> bool:
	"""Check if the fade effect is currently playing"""
	return is_playing_effect

func force_stop_effect():
	"""Force stop the fade effect immediately (useful for debugging or emergency stops)"""
	if is_playing_effect:
		hide_immediately()
