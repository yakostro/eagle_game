extends Node

class_name UIFeedback

# Export NodePaths for robust wiring without relying on global class parsing
@export var nest_spawner_path: NodePath
@export var eagle_path: NodePath
@export var nest_notice_label_path: NodePath
@export var morale_pop_container_path: NodePath
@export var nest_notice_duration: float = 1.5
@export var morale_pop_duration: float = 1.2

var _nest_timer: Timer
var _morale_timer: Timer
var _previous_morale: float = -1.0

var nest_spawner: Node
var eagle: Node
var nest_notice_label: Label
var morale_pop_container: Node
var chicks_label: Label  # "Chicks gonna die" label
var morale_label: Label  # "-Morale" label

func _ready():
	_resolve_nodes()

	if nest_spawner and nest_spawner.has_signal("nest_incoming"):
		if not nest_spawner.nest_incoming.is_connected(_on_nest_incoming):
			nest_spawner.nest_incoming.connect(_on_nest_incoming)
	
	# Connect to nest_spawned signal to connect to individual nest_missed signals
	if nest_spawner and nest_spawner.has_signal("nest_spawned"):
		if not nest_spawner.nest_spawned.is_connected(_on_nest_spawned):
			nest_spawner.nest_spawned.connect(_on_nest_spawned)

	if eagle:
		# Cache current morale if the eagle has the method
		if eagle.has_method("get_current_morale"):
			_previous_morale = eagle.get_current_morale()
		if eagle.has_signal("morale_changed") and not eagle.morale_changed.is_connected(_on_morale_changed):
			eagle.morale_changed.connect(_on_morale_changed)

	if nest_notice_label:
		nest_notice_label.visible = false
	if morale_pop_container:
		morale_pop_container.visible = false

	_nest_timer = Timer.new()
	_nest_timer.one_shot = true
	add_child(_nest_timer)
	_nest_timer.timeout.connect(_hide_nest_notice)

	_morale_timer = Timer.new()
	_morale_timer.one_shot = true
	add_child(_morale_timer)
	_morale_timer.timeout.connect(_hide_morale_pop)

func _on_nest_incoming(_remaining: int):
	if not nest_notice_label:
		return
	nest_notice_label.text = "Nest ahead!"
	nest_notice_label.visible = true
	_nest_timer.start(nest_notice_duration)

func _hide_nest_notice():
	if nest_notice_label:
		nest_notice_label.visible = false

func _on_nest_spawned(nest: Node):
	"""Called when a new nest is spawned - connect to its missed signal"""
	if not nest:
		return
	
	# Connect to this specific nest's missed signal
	if nest.has_signal("nest_missed"):
		nest.nest_missed.connect(_on_nest_missed)

func _on_nest_missed(_points: int = 0):
	"""Called when a nest goes off screen without being fed"""
	if not morale_pop_container:
		return
	
	# Set text for both labels
	if chicks_label:
		chicks_label.text = "Chicks gonna die"
	if morale_label:
		morale_label.text = "-Morale"
		morale_label.modulate = Color(1.0, 0.3, 0.3)  # Red color for negative
	
	# Show the container
	morale_pop_container.visible = true
	_morale_timer.start(morale_pop_duration)

func _on_morale_changed(new_morale: float):
	# Note: The MoralePopContainer is now only used for nest missed feedback
	# Positive morale changes (feeding nests) don't show UI feedback currently
	# If you want to add positive morale feedback, create a separate UI element
	_previous_morale = new_morale

func _hide_morale_pop():
	if morale_pop_container:
		morale_pop_container.visible = false

func _resolve_nodes():
	if nest_spawner_path != NodePath(""):
		nest_spawner = get_node_or_null(nest_spawner_path)
	if not nest_spawner:
		nest_spawner = get_tree().current_scene.find_child("NestSpawner", true, false)

	if eagle_path != NodePath(""):
		eagle = get_node_or_null(eagle_path)
	if not eagle:
		eagle = get_tree().current_scene.find_child("Eagle", true, false)

	if nest_notice_label_path != NodePath(""):
		nest_notice_label = get_node_or_null(nest_notice_label_path) as Label
	if not nest_notice_label:
		nest_notice_label = get_tree().current_scene.find_child("NestNotice", true, false) as Label

	if morale_pop_container_path != NodePath(""):
		morale_pop_container = get_node_or_null(morale_pop_container_path)
	if not morale_pop_container:
		morale_pop_container = get_tree().current_scene.find_child("MoralePopContainer", true, false)
	
	# Find child labels within the container
	if morale_pop_container:
		# Look for common label names - adjust these names as needed
		chicks_label = morale_pop_container.find_child("ChicksLabel", true, false) as Label
		if not chicks_label:
			chicks_label = morale_pop_container.find_child("ChicksDieLabel", true, false) as Label
		
		morale_label = morale_pop_container.find_child("MoraleLabel", true, false) as Label
		if not morale_label:
			morale_label = morale_pop_container.find_child("MoralePop", true, false) as Label
