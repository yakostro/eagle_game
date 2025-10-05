extends Control

class_name UIMessage

# Message types for the queue system (original + extended)
enum MessageType {
	NEST_INCOMING,
	NEST_MISSED
}

# Display mode enumeration for flexible display
enum MessageMode {
	SINGLE_TEXT,     # One centered label
	DOUBLE_TEXT,     # Two labels side by side  
	TEXT_WITH_ICON   # Label + icon
}

# Icon position enumeration
enum IconPosition { 
	LEFT, 
	RIGHT 
}

# Extended message types for flexible display
enum FlexibleMessageType {
	NEST_INCOMING,      # Single text: "Nest ahead!"
	NEST_MISSED,        # Double text: "Nest missed" + "-Morale"  
	ENERGY_GAIN,        # Text + icon: "+20" + energy icon
	ENERGY_LOSS,        # Text + icon: "-15" + energy icon
	FISH_COLLECTED,     # Text + icon: "+Fish" + fish icon
	STAGE_COMPLETE,     # Single text: "Stage Complete!"
	ACHIEVEMENT         # Single text: "Achievement Unlocked!"
}

# Export NodePaths for robust wiring without relying on global class parsing
@export_group("Connections")
@export var nest_spawner_path: NodePath
@export var eagle_path: NodePath
@export var camera_path: NodePath

# Message timing configuration
@export var nest_notice_duration: float = 1.5
@export var nest_missed_duration: float = 2.5  # Longer duration for nest missed messages
@export var inter_message_delay: float = 0.7  # Delay between messages

# Flexible display configuration
@export var message_mode: MessageMode = MessageMode.SINGLE_TEXT
@export var primary_text: String = ""
@export var secondary_text: String = ""
@export var message_icon: Texture2D
@export var icon_position: IconPosition = IconPosition.RIGHT

# Palette
@export var palette: UiPalette

# Visual Styling
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.RED
@export var font_size: int = 32
@export var label_separation: int = 20
@export var icon_size: Vector2 = Vector2(30, 30)

# Animation & Timing
@export var display_duration: float = 1.5
@export var fade_in_time: float = 0.2
@export var fade_out_time: float = 0.3
@export var enable_pulse_animation: bool = false
@export var pulse_speed: float = 0.3  # Time for one pulse cycle (lower = faster blinking)
@export var pulse_scale: float = 1.1  # Scale factor for blinking animation (1.0 = no scaling, higher = more dramatic)

# Message queue system variables
var message_queue: Array[Dictionary] = []
var current_message: Dictionary = {}
var is_showing_message: bool = false
var _message_timer: Timer
var _previous_morale: float = -1.0

# Original external node references (for backward compatibility)
var nest_spawner: Node
var eagle: Node
var nest_notice_label: Label
var morale_pop_container: Node
var chicks_label: Label  # "Chicks gonna die" label
var morale_label: Label  # "-Morale" label
var camera: Camera2D  # Reference to camera for world-to-screen coordinate conversion

# Flexible display node references (for self-contained mode)
var message_container: Control
var content_layout: HBoxContainer
var primary_label: Label
var secondary_label: Label
var message_icon_node: TextureRect

# Animation control
var display_tween: Tween
var pulse_tween: Tween

# Mode detection
var is_flexible_mode: bool = false

func _ready():
	# First check if we're in flexible mode (have our own UI nodes)
	# Ensure palette is available (fallback to default resource if not assigned)
	if not palette:
		var default_palette := load("res://configs/ui/ui_palette_default.tres") as UiPalette
		if default_palette:
			palette = default_palette
	_detect_mode()
	
	if is_flexible_mode:
		_setup_flexible_mode()
	else:
		_setup_legacy_mode()

func _detect_mode():
	"""Detect if we're running in flexible mode or legacy mode"""
	message_container = get_node_or_null("MessageContainer")
	is_flexible_mode = message_container != null

func _setup_flexible_mode():
	"""Setup for flexible text message mode"""
	# Get node references
	_resolve_flexible_ui_nodes()
	
	# Configure initial layout
	_configure_flexible_layout()
	
	# Hide container initially
	if message_container:
		message_container.modulate.a = 0.0
		message_container.visible = false
	
	# Even in flexible mode we still need gameplay nodes (nest_spawner, eagle)
	# so resolve exported NodePaths before wiring signals
	_resolve_nodes()
	
	# Setup basic UIMessage functionality
	_setup_base_functionality()

func _setup_legacy_mode():
	"""Setup for legacy external nodes mode"""
	_resolve_nodes()
	_setup_base_functionality()

func _setup_base_functionality():
	"""Setup the base UIMessage functionality (signals, timer, etc.)"""
	if nest_spawner and nest_spawner.has_signal("nest_incoming"):
		if not nest_spawner.nest_incoming.is_connected(_on_nest_incoming):
			nest_spawner.nest_incoming.connect(_on_nest_incoming)
	
	# Connect to nest_spawned signal to connect to individual nest_missed signals
	if nest_spawner and nest_spawner.has_signal("nest_spawned"):
		if not nest_spawner.nest_spawned.is_connected(_on_nest_spawned):
			nest_spawner.nest_spawned.connect(_on_nest_spawned)

	if eagle:
		# Cache current energy capacity if the eagle has the method
		if eagle.has_method("get_energy_capacity_percentage"):
			_previous_morale = eagle.get_energy_capacity_percentage()
		if eagle.has_signal("energy_capacity_changed") and not eagle.energy_capacity_changed.is_connected(_on_energy_capacity_changed):
			eagle.energy_capacity_changed.connect(_on_energy_capacity_changed)

	if nest_notice_label:
		nest_notice_label.visible = false
	if morale_pop_container:
		morale_pop_container.visible = false

	# Setup unified message timer
	_message_timer = Timer.new()
	_message_timer.one_shot = true
	add_child(_message_timer)
	_message_timer.timeout.connect(_on_message_timer_timeout)
	
	# Start processing message queue
	_process_message_queue()

func _resolve_flexible_ui_nodes():
	"""Get references to flexible UI nodes"""
	if message_container:
		content_layout = message_container.get_node_or_null("ContentLayout") as HBoxContainer
		if content_layout:
			primary_label = content_layout.get_node_or_null("PrimaryLabel") as Label
			secondary_label = content_layout.get_node_or_null("SecondaryLabel") as Label
			message_icon_node = content_layout.get_node_or_null("MessageIcon") as TextureRect

func _configure_flexible_layout():
	"""Configure the flexible layout based on current message mode"""
	if not content_layout:
		return
	
	# Set separation
	content_layout.add_theme_constant_override("separation", label_separation)
	
	# Configure labels
	if primary_label:
		primary_label.add_theme_font_size_override("font_size", font_size)
		primary_label.add_theme_color_override("font_color", (palette.White if palette else primary_color))
		primary_label.text = primary_text
	
	if secondary_label:
		secondary_label.add_theme_font_size_override("font_size", font_size)
		secondary_label.add_theme_color_override("font_color", (palette.Red3 if palette else secondary_color))
		secondary_label.text = secondary_text
	
	# Configure icon
	if message_icon_node:
		message_icon_node.custom_minimum_size = icon_size
		if message_icon:
			message_icon_node.texture = message_icon
	
	# Apply mode-specific visibility and arrangement
	_apply_message_mode()

func _apply_message_mode():
	"""Apply visibility and arrangement based on message mode"""
	if not content_layout:
		return
	
	# Reset all visibility
	if primary_label:
		primary_label.visible = true
	if secondary_label:
		secondary_label.visible = false
	if message_icon_node:
		message_icon_node.visible = false
	
	match message_mode:
		MessageMode.SINGLE_TEXT:
			# Only primary label visible, centered
			pass  # Default state is correct
			
		MessageMode.DOUBLE_TEXT:
			# Both labels visible, side by side
			if secondary_label:
				secondary_label.visible = true
				
		MessageMode.TEXT_WITH_ICON:
			# Primary label + icon visible
			if message_icon_node:
				message_icon_node.visible = true
				
			# Arrange icon position
			_arrange_icon_position()

func _arrange_icon_position():
	"""Arrange icon position relative to text"""
	if not content_layout or not message_icon_node or not primary_label:
		return
	
	# Move icon to correct position in layout
	match icon_position:
		IconPosition.LEFT:
			content_layout.move_child(message_icon_node, 0)  # Move to first position
		IconPosition.RIGHT:
			content_layout.move_child(message_icon_node, -1)  # Move to last position

func show_flexible_message(msg_type: FlexibleMessageType, config: Dictionary = {}):
	"""Show a message with flexible configuration"""
	if not is_flexible_mode:
		print("Warning: show_flexible_message called but not in flexible mode")
		return
	
	# Apply configuration
	if config.has("primary_text"):
		primary_text = config.primary_text
	if config.has("secondary_text"):
		secondary_text = config.secondary_text
	if config.has("primary_color"):
		primary_color = config.primary_color
	if config.has("secondary_color"):
		secondary_color = config.secondary_color
	if config.has("icon_texture"):
		message_icon = config.icon_texture
	if config.has("icon_position"):
		icon_position = config.icon_position
	if config.has("display_duration"):
		display_duration = config.display_duration
	
	# Set message mode based on type
	match msg_type:
		FlexibleMessageType.NEST_INCOMING, FlexibleMessageType.STAGE_COMPLETE, FlexibleMessageType.ACHIEVEMENT:
			message_mode = MessageMode.SINGLE_TEXT
			enable_pulse_animation = false  # No blinking for these messages
		FlexibleMessageType.NEST_MISSED:
			message_mode = MessageMode.DOUBLE_TEXT
			# Enable pulse animation and longer duration for nest missed messages
			if not config.has("display_duration"):
				display_duration = nest_missed_duration
			enable_pulse_animation = true
		FlexibleMessageType.ENERGY_GAIN, FlexibleMessageType.ENERGY_LOSS, FlexibleMessageType.FISH_COLLECTED:
			message_mode = MessageMode.TEXT_WITH_ICON
			enable_pulse_animation = false  # No blinking for these messages
	
	# Reconfigure layout with new settings
	_configure_flexible_layout()
	
	# Show the message with animation
	_animate_show_message()

func _animate_show_message():
	"""Animate showing the message"""
	if not message_container:
		return
	
	# Stop any existing tweens
	if display_tween:
		display_tween.kill()
	if pulse_tween:
		pulse_tween.kill()
	
	# Make container visible but transparent
	message_container.visible = true
	message_container.modulate.a = 0.0
	message_container.scale = Vector2(1.0, 1.0)  # Reset scale
	
	# Create animation sequence
	display_tween = create_tween()
	
	# Fade in
	display_tween.tween_property(message_container, "modulate:a", 1.0, fade_in_time)
	
	# Start continuous blinking if pulse animation is enabled
	if enable_pulse_animation:
		display_tween.tween_callback(_start_continuous_blinking)
	
	# Hold for display duration
	display_tween.tween_interval(display_duration)
	
	# Stop blinking before fade out
	if enable_pulse_animation:
		display_tween.tween_callback(_stop_continuous_blinking)
	
	# Fade out
	display_tween.tween_property(message_container, "modulate:a", 0.0, fade_out_time)
	
	# Hide when done
	display_tween.tween_callback(_hide_flexible_message)

func _hide_flexible_message():
	"""Hide the flexible message container"""
	if message_container:
		message_container.visible = false
	# Make sure to stop blinking when hiding
	_stop_continuous_blinking()

func _start_continuous_blinking():
	"""Start continuous fast blinking animation"""
	if not message_container or not enable_pulse_animation:
		return
	
	# Stop any existing pulse tween
	if pulse_tween:
		pulse_tween.kill()
	
	# Set pivot to center for proper scaling
	var container_size = message_container.size
	message_container.pivot_offset = container_size * 0.5
	
	# Create looping blinking tween
	pulse_tween = create_tween()
	pulse_tween.set_loops()  # Loop infinitely
	
	# Fast blink cycle: scale up -> scale down
	pulse_tween.tween_property(message_container, "scale", Vector2(pulse_scale, pulse_scale), pulse_speed * 0.5)
	pulse_tween.tween_property(message_container, "scale", Vector2(1.0, 1.0), pulse_speed * 0.5)

func _stop_continuous_blinking():
	"""Stop the continuous blinking animation"""
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	
	# Reset scale and pivot to normal
	if message_container:
		message_container.scale = Vector2(1.0, 1.0)
		message_container.pivot_offset = Vector2.ZERO  # Reset pivot to default

# DEBUG CONTROLS COMMENTED OUT - See debug_keyboard_actions.md for re-enable instructions
# func _unhandled_input(event):
# 	"""Handle debug input for testing message queue and flexible display modes"""
# 	if not is_flexible_mode:
# 		return
# 		
# 	if event is InputEventKey and event.pressed:
# 		# DEBUG: U key to test morale UI message (double text mode)
# 		if event.keycode == KEY_U:
# 			print("DEBUG: Testing DOUBLE_TEXT mode - Morale message!")
# 			show_flexible_message(FlexibleMessageType.NEST_MISSED, {
# 				"primary_text": "Nest missed",
# 				"secondary_text": "-MORALE",
# 				"primary_color": (palette.White if palette else Color.WHITE),
# 				"secondary_color": (palette.Red3 if palette else Color.RED)
# 			})
# 			get_viewport().set_input_as_handled()
# 		# DEBUG: I key to test nest UI message (single text mode)
# 		elif event.keycode == KEY_I:
# 			print("DEBUG: Testing SINGLE_TEXT mode - Nest ahead!")
# 			show_flexible_message(FlexibleMessageType.NEST_INCOMING, {
# 				"primary_text": "Nest ahead!",
# 				"primary_color": (palette.White if palette else Color.CYAN)
# 			})
# 			get_viewport().set_input_as_handled()
# 		# DEBUG: O key to test energy message (text + icon mode)
# 		elif event.keycode == KEY_O:
# 			print("DEBUG: Testing TEXT_WITH_ICON mode - Energy gain!")
# 			# Load energy icon for testing
# 			var energy_icon = load("res://sprites/ui/energy_icon_yellow3.png") as Texture2D
# 			show_flexible_message(FlexibleMessageType.ENERGY_GAIN, {
# 				"primary_text": "+20",
# 				"icon_texture": energy_icon,
# 				"primary_color": Color.GREEN,
# 				"icon_position": IconPosition.RIGHT
# 			})
# 			get_viewport().set_input_as_handled()

func _on_nest_incoming(_remaining: int):
	"""Queue nest incoming message instead of showing directly"""
	if is_flexible_mode:
		show_flexible_message(FlexibleMessageType.NEST_INCOMING, {
			"primary_text": "Nest ahead!",
			"primary_color": (palette.White if palette else Color.CYAN),
			"display_duration": nest_notice_duration
		})
	else:
		if not nest_notice_label:
			return
		_add_message_to_queue(MessageType.NEST_INCOMING)

func _hide_nest_notice():
	if is_flexible_mode:
		# Hiding is handled by animation in flexible mode
		pass
	else:
		if nest_notice_label:
			nest_notice_label.visible = false

func _on_nest_spawned(nest: Node):
	"""Called when a new nest is spawned - connect to its missed signal"""
	if not nest:
		return
	
	# Connect to this specific nest's missed signal
	if nest.has_signal("nest_missed"):
		nest.nest_missed.connect(_on_nest_missed)
		print("🔗 UIMessage: Connected to nest.nest_missed signal for nest: ", nest.name)

func _on_nest_missed(_points: int = 0):
	"""Queue morale negative message instead of showing directly"""
	if is_flexible_mode:
		show_flexible_message(FlexibleMessageType.NEST_MISSED, {
			"primary_text": "Nest missed",
			"secondary_text": "-MORALE",
			"primary_color": (palette.White if palette else Color.WHITE),
			"secondary_color": (palette.Red3 if palette else Color.RED),
			"display_duration": nest_missed_duration
		})
	else:
		if not morale_pop_container:
			return
		_add_message_to_queue(MessageType.NEST_MISSED)

func _on_energy_capacity_changed(new_max_energy: float):
	# Handle energy capacity changes (which replaced the morale system)
	# This gets called when nests are missed (capacity decreases) or fed (capacity increases)
	var new_capacity_percentage = new_max_energy / eagle.initial_max_energy if eagle else 0.0
	
	# Check if capacity decreased (nest was missed)
	if _previous_morale > 0 and new_capacity_percentage < _previous_morale:
		print("DEBUG: Energy capacity decreased from ", _previous_morale, " to ", new_capacity_percentage)
		# This indicates a nest was missed - the nest_missed signal should handle the UI message
	
	_previous_morale = new_capacity_percentage

func _hide_morale_pop():
	if is_flexible_mode:
		# Hiding is handled by animation in flexible mode
		pass
	else:
		if morale_pop_container:
			morale_pop_container.visible = false

func _resolve_nodes():
	# Gameplay references - NodePath only, no fallbacks
	if nest_spawner_path == NodePath(""):
		push_error("UIMessage: Missing nest_spawner_path. Please set it in the Inspector.")
	else:
		nest_spawner = get_node_or_null(nest_spawner_path)
		if not nest_spawner:
			push_error("UIMessage: Invalid nest_spawner_path: " + str(nest_spawner_path))

	if eagle_path == NodePath(""):
		push_error("UIMessage: Missing eagle_path. Please set it in the Inspector.")
	else:
		eagle = get_node_or_null(eagle_path)
		if not eagle:
			push_error("UIMessage: Invalid eagle_path: " + str(eagle_path))

	# Camera is required for coordinate conversion in some flows
	if camera_path == NodePath(""):
		push_error("UIMessage: Missing camera_path. Please set it in the Inspector.")
	else:
		camera = get_node_or_null(camera_path) as Camera2D
		if not camera:
			push_error("UIMessage: Invalid camera_path: " + str(camera_path))

## Message Queue System Methods (for legacy mode)

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
			_message_timer.start(nest_missed_duration)

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
		morale_label.text = "-MORALE"
	
	# Show the container
	morale_pop_container.visible = true
