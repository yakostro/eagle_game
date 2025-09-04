extends Node

class_name UIFeedback

# Message types for the queue system
enum MessageType {
	NEST_INCOMING,
	NEST_MISSED,	
	ENERGY_LOSS
}

# Export NodePaths for robust wiring without relying on global class parsing
@export var nest_spawner_path: NodePath
@export var eagle_path: NodePath
@export var nest_notice_label_path: NodePath
@export var morale_pop_container_path: NodePath
@export var energy_feedback_container_path: NodePath
@export var camera_path: NodePath

# Message timing configuration
@export var nest_notice_duration: float = 1.5
@export var morale_pop_duration: float = 1.2
@export var energy_feedback_duration: float = 1.0
@export var inter_message_delay: float = 0.7  # Delay between messages

# Energy feedback positioning relative to eagle
@export var energy_feedback_offset: Vector2 = Vector2(-80, 0)  # Offset from eagle position (left side)

# Message queue system variables
var message_queue: Array[Dictionary] = []
var current_message: Dictionary = {}
var is_showing_message: bool = false
var _message_timer: Timer
var _previous_morale: float = -1.0

var nest_spawner: Node
var eagle: Node
var nest_notice_label: Label
var morale_pop_container: Node
var chicks_label: Label  # "Chicks gonna die" label
var morale_label: Label  # "-Morale" label
var energy_feedback_container: Node
var energy_loss_label: Label  # Energy loss feedback label
var camera: Camera2D  # Reference to camera for world-to-screen coordinate conversion

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
		# Connect to eagle hit signal for energy loss feedback
		if eagle.has_signal("eagle_hit") and not eagle.eagle_hit.is_connected(_on_eagle_hit):
			eagle.eagle_hit.connect(_on_eagle_hit)

	if nest_notice_label:
		nest_notice_label.visible = false
	if morale_pop_container:
		morale_pop_container.visible = false
	if energy_feedback_container:
		energy_feedback_container.visible = false

	# Setup unified message timer
	_message_timer = Timer.new()
	_message_timer.one_shot = true
	add_child(_message_timer)
	_message_timer.timeout.connect(_on_message_timer_timeout)
	
	# Start processing message queue
	_process_message_queue()

func _unhandled_input(event):
	"""Handle debug input for testing message queue"""
	if event is InputEventKey and event.pressed:
		# DEBUG: U key to test morale UI message
		if event.keycode == KEY_U:
			print("DEBUG: Manual morale UI message triggered!")
			_add_message_to_queue(MessageType.NEST_MISSED)
			get_viewport().set_input_as_handled()
		# DEBUG: I key to test nest UI message  
		elif event.keycode == KEY_I:
			print("DEBUG: Manual nest UI message triggered!")
			_add_message_to_queue(MessageType.NEST_INCOMING)
			get_viewport().set_input_as_handled()
		# DEBUG: O key to test energy loss UI message
		elif event.keycode == KEY_O:
			print("DEBUG: Manual energy loss UI message triggered!")
			_add_message_to_queue(MessageType.ENERGY_LOSS, {"amount": 20})
			get_viewport().set_input_as_handled()

func _on_nest_incoming(_remaining: int):
	"""Queue nest incoming message instead of showing directly"""
	if not nest_notice_label:
		return
	_add_message_to_queue(MessageType.NEST_INCOMING)

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
	"""Queue morale negative message instead of showing directly"""
	if not morale_pop_container:
		return
	_add_message_to_queue(MessageType.NEST_MISSED)

func _on_morale_changed(new_morale: float):
	# Note: The MoralePopContainer is now only used for nest missed feedback
	# Positive morale changes (feeding nests) don't show UI feedback currently
	# If you want to add positive morale feedback, create a separate UI element
	_previous_morale = new_morale

func _on_eagle_hit():
	"""Called when eagle gets hit - show energy loss feedback"""
	if not energy_feedback_container:
		return
	# Get the energy loss amount from eagle if available
	var energy_loss_amount = 20  # Default value
	if eagle and "hit_energy_loss" in eagle:
		energy_loss_amount = eagle.hit_energy_loss
	_add_message_to_queue(MessageType.ENERGY_LOSS, {"amount": energy_loss_amount})

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
	
	# Resolve energy feedback UI elements
	if energy_feedback_container_path != NodePath(""):
		energy_feedback_container = get_node_or_null(energy_feedback_container_path)
	if not energy_feedback_container:
		energy_feedback_container = get_tree().current_scene.find_child("EnergyFeedbackContainer", true, false)
	
	# Find energy loss label within the energy feedback container
	if energy_feedback_container:
		energy_loss_label = energy_feedback_container.find_child("EnergyLossLabel", true, false) as Label
	
	# Resolve camera reference for world-to-screen coordinate conversion
	if camera_path != NodePath(""):
		camera = get_node_or_null(camera_path) as Camera2D
	if not camera:
		camera = get_tree().current_scene.find_child("Camera2D", true, false) as Camera2D

## Message Queue System Methods

func _add_message_to_queue(message_type: MessageType, data: Dictionary = {}):
	"""Add a message to the queue for sequential display"""
	var message = {
		"type": message_type,
		"data": data
	}
	message_queue.append(message)
	
	# Start processing if not already busy
	if not is_showing_message:
		_process_message_queue()

func _process_message_queue():
	"""Process the next message in the queue"""
	if is_showing_message or message_queue.is_empty():
		return
	
	# Get next message
	current_message = message_queue.pop_front()
	is_showing_message = true
	
	# Show the message
	_show_current_message()

func _show_current_message():
	"""Display the current message based on its type"""
	match current_message.type:
		MessageType.NEST_INCOMING:
			_show_nest_notice()
			_message_timer.start(nest_notice_duration)
		MessageType.NEST_MISSED:
			_show_morale_popup()
			_message_timer.start(morale_pop_duration)
		MessageType.ENERGY_LOSS:
			_show_energy_loss_feedback()
			_message_timer.start(energy_feedback_duration)

func _on_message_timer_timeout():
	"""Called when current message duration ends"""
	# Hide current message
	_hide_current_message()
	
	# Add inter-message delay before processing next
	_message_timer.start(inter_message_delay)
	_message_timer.timeout.disconnect(_on_message_timer_timeout)
	_message_timer.timeout.connect(_on_delay_timeout)

func _on_delay_timeout():
	"""Called after inter-message delay ends"""
	is_showing_message = false
	
	# Reconnect to main timeout handler
	_message_timer.timeout.disconnect(_on_delay_timeout)
	_message_timer.timeout.connect(_on_message_timer_timeout)
	
	# Process next message in queue
	_process_message_queue()

func _hide_current_message():
	"""Hide the current message based on its type"""
	match current_message.type:
		MessageType.NEST_INCOMING:
			_hide_nest_notice()
		MessageType.NEST_MISSED:
			_hide_morale_pop()
		MessageType.ENERGY_LOSS:
			_hide_energy_loss_feedback()

func _show_nest_notice():
	"""Show nest incoming notification"""
	if nest_notice_label:
		nest_notice_label.text = "Nest ahead!"
		nest_notice_label.visible = true

func _show_morale_popup():
	"""Show morale negative feedback"""
	if not morale_pop_container:
		return
	
	# Set text for both labels
	if chicks_label:
		chicks_label.text = "Chicks gonna die"
	if morale_label:
		morale_label.text = "-Morale"
	
	# Show the container
	morale_pop_container.visible = true

func _show_energy_loss_feedback():
	"""Show energy loss feedback"""
	if not energy_feedback_container:
		return
	
	# Get energy loss amount from message data
	var amount = current_message.data.get("amount", 20)
	
	# Set text for energy loss label
	if energy_loss_label:
		energy_loss_label.text = "-" + str(amount)
	
	# Update position relative to eagle
	_update_energy_feedback_position()
	
	# Show the container
	energy_feedback_container.visible = true

func _update_energy_feedback_position():
	"""Update energy feedback position to be next to the eagle"""
	if not energy_feedback_container or not eagle or not camera:
		return
	
	# Get eagle's world position
	var eagle_world_pos = eagle.global_position
	
	# Convert to screen coordinates
	var eagle_screen_pos = camera.get_screen_center_position() + (eagle_world_pos - camera.global_position)
	
	# Apply offset to position on the left side of eagle
	var feedback_screen_pos = eagle_screen_pos + energy_feedback_offset
	
	# Set the container position
	energy_feedback_container.position = feedback_screen_pos

func _hide_energy_loss_feedback():
	"""Hide energy loss feedback"""
	if energy_feedback_container:
		energy_feedback_container.visible = false
