extends Control
class_name EnergyMoraleUI

## Energy/Morale UI Controller
## Manages unified progress bar showing energy (purple), energy loss feedback (white), and morale capacity lock (gray)

# Node references using NodePath (following project pattern)
@export var energy_icon_path: NodePath = "Container/EnergyIcon"
@export var energy_progress_bar_path: NodePath = "Container/ProgressBarContainer/EnergyProgressBar"
@export var energy_loss_feedback_path: NodePath = "Container/ProgressBarContainer/EnergyLossFeedback"
@export var morale_lock_path: NodePath = "Container/ProgressBarContainer/MoraleLock"

# Tweakable parameters for game balancing
@export_group("Visual Configuration")
@export var energy_color: Color = Color(0.6, 0.3, 0.8, 1.0)  # Purple
@export var energy_loss_feedback_color: Color = Color(1.0, 1.0, 1.0, 0.8)  # White
@export var morale_lock_color: Color = Color(0.4, 0.4, 0.4, 1.0)  # Gray
@export var energy_loss_feedback_duration: float = 0.5  # How long white flash lasts

@export_group("Bar Configuration")
@export var bar_width: float = 300.0
@export var bar_height: float = 40.0
@export var icon_size: Vector2 = Vector2(40, 40)

# Internal references
@onready var energy_icon: TextureRect = get_node(energy_icon_path)
@onready var energy_progress_bar: ProgressBar = get_node(energy_progress_bar_path)
@onready var energy_loss_feedback: ProgressBar = get_node(energy_loss_feedback_path)
@onready var morale_lock: ColorRect = get_node(morale_lock_path)

# Current state tracking
var current_energy_percent: float = 100.0
var current_morale_percent: float = 100.0
var max_available_energy_capacity: float = 100.0

# Animation tweener
var feedback_tween: Tween

# Game integration - connected to eagle signals
@export var eagle_path: NodePath = "../../Eagle"
@onready var eagle: Eagle = get_node(eagle_path)

func _ready():
	setup_ui_elements()
	create_lightning_icon()
	
	# Connect to eagle signals for real-time updates
	connect_to_eagle_signals()

func connect_to_eagle_signals():
	"""Connect UI to eagle's energy and morale systems"""
	if eagle == null:
		eagle = get_node_or_null(eagle_path)
	
	if eagle == null:
		# Try to find eagle in scene tree
		eagle = get_tree().current_scene.find_child("Eagle", true, false) as Eagle
	
	if eagle != null:
		# Connect to morale changes
		if not eagle.morale_changed.is_connected(_on_eagle_morale_changed):
			eagle.morale_changed.connect(_on_eagle_morale_changed)
		
		# Set initial values from eagle
		var initial_energy = (eagle.current_energy / eagle.max_energy) * 100.0
		var initial_morale = (eagle.current_morale / eagle.max_morale) * 100.0
		
		set_energy_percent_direct(initial_energy)
		set_morale_percent_direct(initial_morale)
		
		print("✅ EnergyMoraleUI connected to eagle signals")
		print("   Initial Energy: ", initial_energy, "%")
		print("   Initial Morale: ", initial_morale, "%")
	else:
		print("❌ Warning: Could not find Eagle to connect UI signals")

## Signal handlers for eagle integration

func _on_eagle_morale_changed(new_morale: float):
	"""Called when eagle's morale changes"""
	var morale_percent = (new_morale / eagle.max_morale) * 100.0
	set_morale_percent_direct(morale_percent)

func _physics_process(_delta):
	"""Update energy display each frame (since energy changes continuously)"""
	if eagle != null:
		var energy_percent = (eagle.current_energy / eagle.max_energy) * 100.0
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

func set_morale_percent_direct(new_morale_percent: float):
	"""Update morale level without UI feedback, affects energy capacity"""
	current_morale_percent = clamp(new_morale_percent, 0.0, 100.0)
	
	# Morale affects maximum available energy capacity
	max_available_energy_capacity = current_morale_percent
	
	# If current energy exceeds new capacity, clamp it
	if current_energy_percent > max_available_energy_capacity:
		current_energy_percent = max_available_energy_capacity
	
	update_energy_display()
	update_morale_capacity_display()

func setup_ui_elements():
	"""Configure the UI elements with exported parameters"""
	# Apply colors using theme overrides for ProgressBar nodes
	apply_progress_bar_colors()
	
	# Set sizes
	var container = get_node("Container/ProgressBarContainer") as Control
	container.custom_minimum_size = Vector2(bar_width, bar_height)
	energy_icon.custom_minimum_size = icon_size
	
	# Initialize values
	update_energy_display()
	update_morale_capacity_display()

func apply_progress_bar_colors():
	"""Apply colors to progress bars using theme overrides"""
	# Energy progress bar (purple)
	energy_progress_bar.add_theme_color_override("font_color", energy_color)
	energy_progress_bar.add_theme_color_override("font_outline_color", Color.BLACK)
	energy_progress_bar.add_theme_constant_override("outline_size", 1)
	
	# Create a StyleBoxFlat for the progress fill
	var energy_style = StyleBoxFlat.new()
	energy_style.bg_color = energy_color
	energy_progress_bar.add_theme_stylebox_override("fill", energy_style)
	
	# Energy loss feedback (white)
	var feedback_style = StyleBoxFlat.new()
	feedback_style.bg_color = energy_loss_feedback_color
	energy_loss_feedback.add_theme_stylebox_override("fill", feedback_style)
	
	# Morale lock (gray) - ColorRect just needs its color set
	morale_lock.color = morale_lock_color
	
	# Set background for progress bars
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark background
	energy_progress_bar.add_theme_stylebox_override("background", bg_style)
	energy_loss_feedback.add_theme_stylebox_override("background", bg_style)

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
	"""Show white feedback for energy loss"""
	# Stop any existing feedback animation
	if feedback_tween:
		feedback_tween.kill()
	
	# Set up the feedback overlay
	energy_loss_feedback.value = current_energy_percent + loss_amount
	energy_loss_feedback.visible = true
	
	# Animate the feedback away
	feedback_tween = create_tween()
	feedback_tween.tween_method(animate_energy_loss_feedback, current_energy_percent + loss_amount, current_energy_percent, energy_loss_feedback_duration)
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

func update_morale_capacity_display():
	"""Update the gray morale lock area from the right side"""
	# Calculate locked capacity percentage (100% - morale%)
	var locked_capacity_percent = 100.0 - current_morale_percent
	
	# Calculate the width of the gray area in pixels
	var locked_width = bar_width * (locked_capacity_percent / 100.0)
	
	# Position the ColorRect from the right side
	# Since it's anchored to the right (anchor_left = 1.0), we use negative offset_left
	morale_lock.offset_left = -locked_width
	
## Utility methods for external access

func get_current_energy_percent() -> float:
	return current_energy_percent

func get_current_morale_percent() -> float:
	return current_morale_percent

func get_max_available_capacity() -> float:
	return max_available_energy_capacity
