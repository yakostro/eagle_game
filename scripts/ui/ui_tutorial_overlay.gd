extends Control

# Overlay that shows a stage-specific tutorial image briefly at stage start.

@export var tutorial_image_path: NodePath ## Path to the tutorial image texture rect
@export var stage_to_texture: Dictionary = {} ## Map stage_id to texture (stage_id: texture)	
@export var show_duration: float = 3.0 ## Default show duration in seconds
@export var fade_in_duration: float = 0.25 ## Fade in duration in seconds
@export var fade_out_duration: float = 0.25 ## Fade out duration in seconds
@export var stage_to_duration: Dictionary = {} ## Override show duration for specific stages (stage_id: duration_in_seconds)
@export var default_delay: float = 0.5 ## Default delay in seconds
@export var stage_to_delay: Dictionary = {} ## Override delay for specific stages (stage_id: delay_in_seconds)

@onready var tutorialImage: TextureRect = get_node_or_null(tutorial_image_path)

var _shown_stages: Dictionary = {} ## Track which stages have been shown	
var _current_tween: Tween

func _ready():
	# Ensure initial hidden state and non-blocking input
	visible = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Show for the current stage on startup, and connect for subsequent stage changes
	if Engine.has_singleton("StageManager"):
		# Not used; we reference autoload directly
		pass

	if typeof(StageManager) != TYPE_NIL:
		if not StageManager.stage_changed.is_connected(_on_stage_changed):
			StageManager.stage_changed.connect(_on_stage_changed)
		var current_stage: int = StageManager.get_current_stage()
		_try_show_for_stage(current_stage)

func _on_stage_changed(new_stage: int, _config):
	_try_show_for_stage(new_stage)

func _try_show_for_stage(stage_id: int):
	if not stage_to_texture.has(stage_id):
		return
	if _shown_stages.has(stage_id):
		return
	_shown_stages[stage_id] = true
	show_for_stage(stage_id)

func show_for_stage(stage_id: int):
	if not tutorialImage:
		return
	var tex = stage_to_texture.get(stage_id, null)
	if tex == null:
		return
	tutorialImage.texture = tex
	
	# Get stage-specific delay and duration
	var delay = stage_to_delay.get(stage_id, default_delay)
	var duration = stage_to_duration.get(stage_id, show_duration)
	
	# Ensure values are floats (in case they come as string or int from scene)
	if typeof(delay) == TYPE_STRING:
		delay = float(delay)
	elif typeof(delay) == TYPE_INT:
		delay = float(delay)
		
	if typeof(duration) == TYPE_STRING:
		duration = float(duration)
	elif typeof(duration) == TYPE_INT:
		duration = float(duration)
	
	# Wait for delay, then show the overlay
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	_play_show_then_hide(duration)

func _play_show_then_hide(duration: float):
	if _current_tween:
		_current_tween.kill()

	visible = true
	modulate.a = 0.0
	
	_current_tween = get_tree().create_tween()
	_current_tween.tween_property(self, "modulate:a", 1.0, fade_in_duration).from(0.0)
	_current_tween.tween_interval(duration)
	_current_tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	_current_tween.tween_callback(func(): 
		visible = false
	)


