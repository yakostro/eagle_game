class_name Eagle
extends CharacterBody2D

#@onready var animated_sprite = $Animation
#@onready var animated_sprite = $AnimatedSprite2D
@onready var screech_audio = $Screech
@onready var state_label = $"../CanvasLayer/StateLabel"

@export var animated_sprite: AnimatedSprite2D

# Movement states - simple and focused
enum MovementState { GLIDING, LIFTING, DIVING }

# Physics constants
const MAX_UP_VELOCITY = -600.0
const MAX_DOWN_VELOCITY = 800.0
const LIFT_ACCELERATION = 11000.0
const DIVE_ACCELERATION = 12000.0
const DRAG = 500.0
const NEUTRAL_DRAG = 800.0
const NEUTRAL_THRESHOLD = 5.0

# Rotation constants
const MAX_ROTATION_UP = -45.0
const MAX_ROTATION_DOWN = 45.0
const ROTATION_SPEED = 3.0
const MIN_SPEED_FOR_ROTATION = 50.0
const MAX_SPEED_FOR_ROTATION = 1000.0

# Game mechanics variables
@export var max_energy: float = 100.0
@export var energy_per_fish: float = 25.0  # Energy gained from eating fish
@export var energy_loss_per_second: float = 5.0  # Base energy loss over time

# Components
var movement_state: MovementState = MovementState.GLIDING
var animation_controller: EagleAnimationController

# Energy and fish tracking
var current_energy: float = 100.0
var carried_fish: Fish = null  # Reference to the carried fish object

# Signals
signal movement_state_changed(old_state: MovementState, new_state: MovementState)
signal screech_requested()
signal fish_caught_changed(has_fish: bool)  # Signal when fish carrying state changes

func _ready():
	print("Eagle ready! Node name: ", name)
	
	# Initialize animation controller
	animation_controller = EagleAnimationController.new(animated_sprite)
	add_child(animation_controller)
	
	# Connect signals
	movement_state_changed.connect(animation_controller.handle_movement_state_change)
	screech_requested.connect(animation_controller.handle_screech_request)
	fish_caught_changed.connect(animation_controller.handle_fish_carrying_change)

func _physics_process(delta):
	# 1. Handle special input actions
	handle_special_inputs()
	
	# 2. Handle fish actions
	handle_fish_actions()
	
	# 3. Update energy
	update_energy(delta)
	
	# 4. Update movement state
	update_movement_state()
	
	# 5. Apply physics based on current state
	apply_movement_physics(delta)
	
	# 6. Update rotation
	update_rotation(delta)
	
	# 7. Apply movement
	move_and_slide()
	
	# 8. Update UI
	update_UI()

# Fish management methods
func catch_fish(fish: Fish):
	"""Called when the eagle catches a fish"""
	if carried_fish == null:  # Only catch if not already carrying
		carried_fish = fish
		print("Eagle caught a fish!")
		fish_caught_changed.emit(true)

func eat_fish():
	"""Called when the eagle eats a caught fish to restore energy"""
	if carried_fish != null:
		print("Eagle ate a fish!")
		current_energy = min(current_energy + energy_per_fish, max_energy)
		carried_fish.queue_free()  # Remove the fish from scene
		carried_fish = null
		fish_caught_changed.emit(false)
		return true
	return false

func drop_fish():
	"""Called when the eagle drops a fish to feed chicks"""
	if carried_fish != null:
		print("Eagle dropped a fish!")
		carried_fish.release_fish()  # Release the fish back to the world
		carried_fish = null
		fish_caught_changed.emit(false)
		return true
	return false

func has_fish() -> bool:
	"""Returns true if eagle is carrying a fish"""
	return carried_fish != null

func handle_fish_actions():
	"""Handle input for eating or dropping fish"""
	if carried_fish != null:
		if Input.is_action_just_pressed("eat_fish"):
			eat_fish()
		elif Input.is_action_just_pressed("drop_fish"):
			drop_fish()

func update_energy(delta):
	"""Update eagle's energy over time"""
	# Lose energy over time (faster if low morale in future)
	current_energy -= energy_loss_per_second * delta
	current_energy = max(current_energy, 0.0)
	
	# TODO: Add death condition when energy reaches 0

func handle_special_inputs():
	# Handle screech input (H button)
	if Input.is_action_just_pressed("screech"):
		# Play screech sound
		screech_audio.play()
		# Trigger screech animation
		screech_requested.emit()

func update_movement_state():
	var new_state = determine_movement_state()
	
	if new_state != movement_state:
		var old_state = movement_state
		movement_state = new_state
		movement_state_changed.emit(old_state, new_state)

func determine_movement_state() -> MovementState:
	if Input.is_action_pressed("move_up"):
		return MovementState.LIFTING
	elif Input.is_action_pressed("move_down"):
		if velocity.y > 200.0:  # Fast downward = diving
			return MovementState.DIVING
		else:
			return MovementState.LIFTING
	else:
		return MovementState.GLIDING

func apply_movement_physics(delta):
	match movement_state:
		MovementState.LIFTING:
			apply_lifting_physics(delta)
		MovementState.DIVING:
			apply_diving_physics(delta)
		MovementState.GLIDING:
			apply_gliding_physics(delta)
	
	# Clamp velocity
	velocity.y = clamp(velocity.y, MAX_UP_VELOCITY, MAX_DOWN_VELOCITY)

func apply_lifting_physics(delta):
	if Input.is_action_pressed("move_up"):
		velocity.y -= LIFT_ACCELERATION * delta
	elif Input.is_action_pressed("move_down"):
		velocity.y += DIVE_ACCELERATION * delta

func apply_diving_physics(delta):
	# Enhanced downward acceleration for diving
	velocity.y += DIVE_ACCELERATION * 1.5 * delta

func apply_gliding_physics(delta):
	# Gentle return to neutral during gliding
	if velocity.y > NEUTRAL_THRESHOLD:
		velocity.y -= NEUTRAL_DRAG * delta
	elif velocity.y < -NEUTRAL_THRESHOLD:
		velocity.y += NEUTRAL_DRAG * delta
	else:
		velocity.y = 0.0

func update_rotation(delta):
	var speed = velocity.length()
	var target_rotation = 0.0
	
	if speed > MIN_SPEED_FOR_ROTATION:
		var speed_ratio = clamp((speed - MIN_SPEED_FOR_ROTATION) / (MAX_SPEED_FOR_ROTATION - MIN_SPEED_FOR_ROTATION), 0.0, 1.0)
		
		if velocity.y < 0:
			target_rotation = -speed_ratio * abs(MAX_ROTATION_UP)
		elif velocity.y > 0:
			target_rotation = speed_ratio * MAX_ROTATION_DOWN
	
	var current_rotation_deg = rad_to_deg(rotation)
	var new_rotation_deg = lerp(current_rotation_deg, target_rotation, ROTATION_SPEED * delta)
	rotation = deg_to_rad(new_rotation_deg)

func update_UI():
	state_label.text = str(MovementState.keys()[movement_state])
	
	# Add fish carrying status and energy to UI
	if has_fish():
		state_label.text += " [FISH]"
	
	state_label.text += " Energy: " + str(int(current_energy))
