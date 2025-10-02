extends Control
class_name EnergyUI

@export var palette: UiPalette
@export var energy_token: StringName = &"Yellow2"
@export var energy_loss_feedback_token: StringName = &"White"
@export var capacity_lock_token: StringName = &"Black"
@export var background_token: StringName = &"Purple1"
@export var border_token: StringName = &"Yellow1"

## Energy UI Controller
## Manages unified progress bar showing energy (purple), energy loss feedback (white), and energy capacity lock (gray)

# Node references using NodePath (following project pattern)
@export var energy_icon_path: NodePath = "Container/EnergyIcon"
@export var energy_progress_bar_path: NodePath = "Container/ProgressBarContainer/EnergyProgressBar"
@export var energy_loss_feedback_path: NodePath = "Container/ProgressBarContainer/EnergyLossFeedback"
@export var capacity_lock_path: NodePath = "Container/ProgressBarContainer/MoraleLock"

# Tweakable parameters for game balancing
@export_group("Visual Configuration")
@export var diagonal_pattern_texture: Texture2D = preload("res://sprites/ui/diagonal_pattern.png")  # Disabled pattern
@export var energy_loss_feedback_duration: float = 0.5  # How long white flash lasts

@export_group("Bar Configuration")
@export var bar_width: float = 300.0
@export var bar_height: float = 18.0
@export var icon_size: Vector2 = Vector2(20, 20)

# Internal references
@onready var energy_icon: TextureRect = get_node(energy_icon_path)
@onready var energy_progress_bar: ProgressBar = get_node(energy_progress_bar_path)
@onready var energy_loss_feedback: ProgressBar = get_node(energy_loss_feedback_path)
@onready var capacity_lock: ColorRect = get_node(capacity_lock_path)

# Current state tracking
var current_energy_percent: float = 100.0
var current_capacity_percent: float = 100.0
var max_available_energy_capacity: float = 100.0

# Animation tweener
var feedback_tween: Tween

# Game integration - connected to eagle signals
@export var eagle_path: NodePath = "../../Eagle"
@onready var eagle: Eagle = get_node(eagle_path)

func _ready():
	print("🎮 EnergyUI _ready() called")
	setup_ui_elements()
	create_lightning_icon()
	
	# Connect to eagle signals for real-time updates
	connect_to_eagle_signals()
	
	# Debug: Print initial values
	print("🎮 Initial energy percent: ", current_energy_percent)
	print("🎮 Initial capacity percent: ", current_capacity_percent)

func connect_to_eagle_signals():
	"""Connect UI to eagle's energy and energy capacity systems"""
	if eagle == null:
		eagle = get_node_or_null(eagle_path)
	
	if eagle == null:
		# Try to find eagle in scene tree
		eagle = get_tree().current_scene.find_child("Eagle", true, false) as Eagle
	
	if eagle != null:
		# Connect to energy capacity changes
		if not eagle.energy_capacity_changed.is_connected(_on_eagle_energy_capacity_changed):
			eagle.energy_capacity_changed.connect(_on_eagle_energy_capacity_changed)
		
		# Set initial values from eagle
		# Calculate energy as percentage of ORIGINAL capacity for consistency
		var initial_energy = (eagle.current_energy / eagle.initial_max_energy) * 100.0
		var initial_capacity = eagle.get_energy_capacity_percentage() * 100.0

		set_energy_percent_direct(initial_energy)
		set_capacity_percent_direct(initial_capacity)
		
		print("✅ EnergyUI connected to eagle signals")
		print("   Initial Energy: ", initial_energy, "%")
		print("   Initial Capacity: ", initial_capacity, "%")
	else:
		print("❌ Warning: Could not find Eagle to connect UI signals")

## Signal handlers for eagle integration

func _on_eagle_energy_capacity_changed(_new_max_energy: float):
	"""Called when eagle's energy capacity changes"""
	var capacity_percent = eagle.get_energy_capacity_percentage() * 100.0
	print("🔧 DEBUG: UI received capacity change signal - new_max_energy: ", _new_max_energy, " capacity_percent: ", capacity_percent)
	set_capacity_percent_direct(capacity_percent)

func _physics_process(_delta):
	"""Update energy display each frame (since energy changes continuously)"""
	if eagle != null:
		# Calculate energy as percentage of ORIGINAL capacity, not current reduced capacity
		# This ensures energy can't appear to exceed the morale lock visually
		var energy_percent = (eagle.current_energy / eagle.initial_max_energy) * 100.0
		set_energy_percent_direct(energy_percent)

## Direct update methods (without UI feedback loops)

func set_energy_percent_direct(new_energy_percent: float):
	"""Update energy level without triggering feedback animation"""
	var old_energy = current_energy_percent
	current_energy_percent = clamp(new_energy_percent, 0.0, max_available_energy_capacity)
	
	# Show energy loss feedback if energy decreased
	if current_energy_percent < old_energy:
		show_energy_loss_feedback(old_energy - current_energy_percent)
	
	update_energy_display()

func set_capacity_percent_direct(new_capacity_percent: float):
	"""Update energy capacity level without UI feedback, affects energy capacity"""
	var old_capacity = current_capacity_percent
	current_capacity_percent = clamp(new_capacity_percent, 0.0, 100.0)
	
	print("🔧 DEBUG: UI capacity update - old: ", old_capacity, "% new: ", current_capacity_percent, "%")
	
	# Capacity affects maximum available energy capacity
	max_available_energy_capacity = current_capacity_percent
	
	# If current energy exceeds new capacity, clamp it
	if current_energy_percent > max_available_energy_capacity:
		current_energy_percent = max_available_energy_capacity
	
	update_energy_display()
	update_capacity_display()

func setup_ui_elements():
	"""Configure the UI elements with exported parameters"""
	# Apply colors using theme overrides for ProgressBar nodes
	apply_progress_bar_colors()
	
	# Set sizes
	var container = get_node("Container/ProgressBarContainer") as Control
	container.custom_minimum_size = Vector2(bar_width, bar_height)
	energy_icon.custom_minimum_size = icon_size
	
	# Configure energy loss feedback overlay as a sized strip we can position
	energy_loss_feedback.anchor_left = 0.0
	energy_loss_feedback.anchor_right = 0.0
	energy_loss_feedback.anchor_top = 0.0
	energy_loss_feedback.anchor_bottom = 1.0
	energy_loss_feedback.offset_left = 0.0
	energy_loss_feedback.offset_right = 0.0
	energy_loss_feedback.value = 100.0
	energy_loss_feedback.z_index = 1
	
	# Initialize values
	update_energy_display()
	update_capacity_display()
	
	# Ensure the energy loss feedback overlay starts hidden so it doesn't cover the main bar
	energy_loss_feedback.visible = false
	
	# Create diagonal pattern overlay
	create_diagonal_pattern_overlay()

func apply_progress_bar_colors():
	"""Apply colors to progress bars using theme overrides"""
	print("🎨 Applying progress bar colors...")
	
	var _energy_color: Color = _get_color(energy_token)
	var _energy_loss_feedback_color: Color = _get_color(energy_loss_feedback_token)
	var _background_color: Color = _get_color(background_token)
	var _border_color: Color = _get_color(border_token)
	var _capacity_lock_color: Color = _get_color(capacity_lock_token)
	
	# Energy progress bar (from palette or fallback)
	energy_progress_bar.add_theme_color_override("font_color", _energy_color)
	energy_progress_bar.add_theme_color_override("font_outline_color", Color.BLACK)
	energy_progress_bar.add_theme_constant_override("outline_size", 1)
	
	# Create a StyleBoxFlat for the progress fill without border
	var energy_style = StyleBoxFlat.new()
	energy_style.bg_color = _energy_color
	energy_style.border_width_left = 0
	energy_style.border_width_right = 0
	energy_style.border_width_top = 0
	energy_style.border_width_bottom = 0
	energy_progress_bar.add_theme_stylebox_override("fill", energy_style)
	
	# Energy loss feedback (white)
	var feedback_style = StyleBoxFlat.new()
	feedback_style.bg_color = _energy_loss_feedback_color
	energy_loss_feedback.add_theme_stylebox_override("fill", feedback_style)
	
	# Capacity lock (gray) - ColorRect just needs its color set
	capacity_lock.color = _capacity_lock_color
	
	# Set background for progress bars with borders
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = _background_color
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = _border_color
	energy_progress_bar.add_theme_stylebox_override("background", bg_style)
	# Make feedback background fully transparent so only the white fill segment is visible
	var feedback_bg_style = StyleBoxFlat.new()
	feedback_bg_style.bg_color = Color(0, 0, 0, 0)
	feedback_bg_style.border_width_left = 0
	feedback_bg_style.border_width_right = 0
	feedback_bg_style.border_width_top = 0
	feedback_bg_style.border_width_bottom = 0
	energy_loss_feedback.add_theme_stylebox_override("background", feedback_bg_style)
	
	print("🎨 Progress bar styling complete!")

func _get_color(token: StringName) -> Color:
	if palette:
		var value = palette.get(String(token))
		if typeof(value) == TYPE_COLOR:
			return value
	match String(token):
		"Yellow1":
			return Color(0.458824, 0.372549, 0.152941, 1.0)
		"Yellow2":
			return Color(0.772549, 0.615686, 0.223529, 1.0)
		"Yellow3":
			return Color(0.909804, 0.72549, 0.258824, 1.0)
		"Red2":
			return Color(0.8, 0.282353, 0.282353, 1.0)
		"Red3":
			return Color(0.956863, 0.32549, 0.32549, 1.0)
		"Purple1":
			return Color(0.219608, 0.14902, 0.243137, 1.0)
		"Black":
			return Color(0.070588, 0.058824, 0.086275, 1.0)
		"White":
			return Color(0.890196, 0.866667, 0.909804, 1.0)
		_:
			return Color(1, 1, 1, 1)

func create_diagonal_pattern_overlay():
	"""Create a diagonal pattern overlay for the energy capacity lock area"""
	var container = get_node("Container/ProgressBarContainer") as Control
	
	# Remove any existing diagonal overlay
	var existing_overlay = container.get_node_or_null("DiagonalPatternOverlay")
	if existing_overlay:
		existing_overlay.queue_free()
	
	# Only create pattern if there's actually locked capacity
	var locked_capacity_percent = 100.0 - current_capacity_percent
	if locked_capacity_percent <= 0:
		return
	
	# Create TextureRect for the diagonal pattern
	var pattern_overlay = TextureRect.new()
	pattern_overlay.name = "DiagonalPatternOverlay"
	pattern_overlay.texture = diagonal_pattern_texture
	pattern_overlay.stretch_mode = TextureRect.STRETCH_TILE
	
	# Position it exactly like the capacity lock ColorRect
	pattern_overlay.anchor_left = 1.0
	pattern_overlay.anchor_right = 1.0
	pattern_overlay.anchor_top = 0.0
	pattern_overlay.anchor_bottom = 1.0
	
	# Calculate the same width as the capacity lock
	var locked_width = bar_width * (locked_capacity_percent / 100.0)
	pattern_overlay.offset_left = -locked_width
	pattern_overlay.offset_right = 0.0
	pattern_overlay.offset_top = 0.0
	pattern_overlay.offset_bottom = 0.0
	
	# Make it non-interactive
	pattern_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add as child of the progress bar container
	container.add_child(pattern_overlay)

func create_lightning_icon():
	"""Create a simple lightning bolt icon programmatically"""
	if energy_icon.texture == null:
		# Create a simple lightning bolt using a label as placeholder
		var lightning_label = Label.new()
		lightning_label.text = "⚡"
		lightning_label.add_theme_font_size_override("font_size", 24)
		lightning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lightning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Replace TextureRect with Label for now
		energy_icon.add_child(lightning_label)
		energy_icon.visible = true

## Private update methods

func show_energy_loss_feedback(loss_amount: float):
	"""Show a white strip representing the lost energy segment on the right of the current energy."""
	# Stop any existing feedback animation
	if feedback_tween:
		feedback_tween.kill()

	# Compute positions in pixels along the bar
	var old_energy_percent = clamp(current_energy_percent + loss_amount, 0.0, 100.0)
	var container := get_node("Container/ProgressBarContainer") as Control
	var total_width: float = bar_width
	if container and container.size.x > 0.0:
		total_width = container.size.x
	var left_px = total_width * (current_energy_percent / 100.0)
	var right_px = total_width * (old_energy_percent / 100.0)
	var width_px = max(right_px - left_px, 0.0)

	# Configure the overlay as a segment [left_px, right_px]
	energy_loss_feedback.value = 100.0
	energy_loss_feedback.offset_left = left_px
	energy_loss_feedback.offset_right = left_px + width_px
	energy_loss_feedback.visible = true

	# Animate the right edge shrinking to the left edge, then hide
	feedback_tween = create_tween()
	feedback_tween.tween_property(energy_loss_feedback, "offset_right", energy_loss_feedback.offset_left, energy_loss_feedback_duration)
	feedback_tween.tween_callback(hide_energy_loss_feedback)

func animate_energy_loss_feedback(value: float):
	"""Animation callback for energy loss feedback"""
	energy_loss_feedback.value = value

func hide_energy_loss_feedback():
	"""Hide the energy loss feedback overlay"""
	energy_loss_feedback.visible = false

func update_energy_display():
	"""Update the main energy progress bar"""
	energy_progress_bar.value = current_energy_percent
	# Debug print removed to reduce console spam

func update_capacity_display():
	"""Update the gray energy capacity lock area from the right side"""
	# Calculate locked capacity percentage (100% - capacity%)
	var locked_capacity_percent = 100.0 - current_capacity_percent
	
	# Calculate the width of the gray area in pixels
	var locked_width = bar_width * (locked_capacity_percent / 100.0)
	
	# Position the ColorRect from the right side
	# Since it's anchored to the right (anchor_left = 1.0), we use negative offset_left
	capacity_lock.offset_left = -locked_width
	
	# Update diagonal pattern overlay
	create_diagonal_pattern_overlay()
	
## Utility methods for external access

func get_current_energy_percent() -> float:
	return current_energy_percent

func get_current_capacity_percent() -> float:
	return current_capacity_percent

func get_max_available_capacity() -> float:
	return max_available_energy_capacity
