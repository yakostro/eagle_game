# Flappy Bird style movement controller for the eagle
# Implements gravity-like descent with flap-based upward movement

class_name FlappyMovementController
extends BaseMovementController

# Physics constants for Flappy Bird mechanics
@export var gravity: float = 50.0  # Constant downward force
@export var flap_force: float = -300.0  # Upward force when flapping (negative = up)
@export var max_fall_velocity: float = 400.0  # Maximum downward velocity
@export var max_rise_velocity: float = -300.0  # Maximum upward velocity (negative = up)
@export var ascent_drag: float = 400.0  # Extra drag applied to upward movement when not flapping

# Dive mechanics (preserving from original system)
@export var dive_acceleration: float = 1500.0  # Extra acceleration when diving
@export var max_dive_velocity: float = 800.0  # Maximum velocity when diving

# Rotation constants
@export var max_rotation_up: float = -30.0  # Rotation when moving up (degrees) - gentle
@export var max_rotation_down: float = 80.0  # Rotation when moving down (degrees) - dramatic
@export var rotation_speed_normal: float = 0.5  # Normal rotation speed
@export var rotation_speed_correction: float = 2.0  # Fast rotation when correcting from down to up
@export var min_speed_for_rotation: float = 60.0  # Minimum speed to start rotating

# Input state tracking
var flap_pressed_this_frame: bool = false
var dive_pressed: bool = false

# Hit state tracking
var previous_movement_state: MovementState = MovementState.GLIDING

func _init(body: CharacterBody2D):
	super._init(body)

func handle_input_and_update_state():
	"""Handle input and determine movement state for Flappy Bird mechanics"""
	# Track input states
	flap_pressed_this_frame = Input.is_action_just_pressed("move_up")
	dive_pressed = Input.is_action_pressed("move_down")
	
	var new_state = determine_movement_state()
	
	if new_state != movement_state:
		set_movement_state(new_state)

func determine_movement_state() -> MovementState:
	"""Determine movement state based on input and velocity"""
	if flap_pressed_this_frame:
		return MovementState.LIFTING
	elif dive_pressed:
		var current_velocity = get_velocity()
		# If already moving fast downward, enter diving state
		if current_velocity.y > 200.0:
			return MovementState.DIVING
		else:
			return MovementState.DIVING  # Start diving
	else:
		return MovementState.GLIDING

func apply_movement_physics(delta: float):
	"""Apply Flappy Bird physics based on current state"""
	var current_velocity = get_velocity()
	
	match movement_state:
		MovementState.LIFTING:
			current_velocity = apply_flap_physics(current_velocity, delta)
		MovementState.DIVING:
			current_velocity = apply_diving_physics(current_velocity, delta)
		MovementState.GLIDING:
			current_velocity = apply_gravity_physics(current_velocity, delta)
		MovementState.HIT:
			current_velocity = apply_hit_physics(current_velocity, delta)
	
	# Clamp velocity to reasonable limits
	if movement_state == MovementState.DIVING:
		current_velocity.y = clamp(current_velocity.y, max_rise_velocity, max_dive_velocity)
	else:
		current_velocity.y = clamp(current_velocity.y, max_rise_velocity, max_fall_velocity)
	
	set_velocity(current_velocity)

func apply_flap_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply upward flap force and gravity"""
	if flap_pressed_this_frame:
		# Add upward impulse (flap) to existing velocity - allows building up speed!
		velocity.y += flap_force
		# Signal eagle that energy should be consumed for flapping
		if eagle_body and eagle_body.has_method("consume_flap_energy"):
			eagle_body.consume_flap_energy()
		# Play flapping sound
		if eagle_body and eagle_body.has_method("play_flap_sound"):
			eagle_body.play_flap_sound()
	
	# Always apply gravity
	velocity.y += gravity * delta
	
	return velocity

func apply_diving_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply enhanced diving physics"""
	# Apply gravity plus extra dive acceleration
	velocity.y += (gravity + dive_acceleration) * delta
	
	return velocity

func apply_gravity_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply gravity during gliding - the core of Flappy Bird mechanics"""
	# Constant gravity pulls eagle down
	velocity.y += gravity * delta
	
	# Apply extra drag to upward movement when not actively flapping
	# This makes the eagle stop ascending quickly after releasing UP
	if velocity.y < 0:  # Moving upward
		velocity.y += ascent_drag * delta  # Add drag (positive value slows upward movement)
	
	return velocity

func apply_hit_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply physics during hit state - maintain momentum with gravity"""
	# During hit, eagle is affected by gravity but can't control movement
	velocity.y += gravity * delta
	
	return velocity

func update_rotation(delta: float):
	"""Update rotation based on velocity with fast correction from positive to negative angles"""
	var velocity = get_velocity()
	var speed = abs(velocity.y)  # Only consider vertical speed for rotation
	var target_rotation = 0.0
	
	if speed > min_speed_for_rotation:
		if velocity.y < 0:  # Moving up
			target_rotation = max_rotation_up
		elif velocity.y > 0:  # Moving down
			# Scale rotation based on speed for more dramatic effect
			var speed_ratio = clamp(speed / max_fall_velocity, 0.0, 1.0)
			target_rotation = speed_ratio * max_rotation_down
	
	# Determine rotation speed based on direction of rotation change
	var current_rotation_deg = rad_to_deg(get_rotation())
	var rotation_speed_to_use = rotation_speed_normal
	
	# Fast correction when rotating counterclockwise from positive angle toward zero/negative
	# (Eagle correcting from downward tilt back to upward tilt)
	if current_rotation_deg > 0 and target_rotation < current_rotation_deg:
		rotation_speed_to_use = rotation_speed_correction
	
	# Smoothly interpolate to target rotation with appropriate speed
	var new_rotation_deg = lerp(current_rotation_deg, target_rotation, rotation_speed_to_use * delta)
	set_rotation(deg_to_rad(new_rotation_deg))

func handle_hit_state():
	"""Handle hit state logic - preserve previous state for recovery"""
	if movement_state != MovementState.HIT:
		previous_movement_state = movement_state
	force_hit_state()

func restore_from_hit_state():
	"""Restore from hit state to previous state"""
	end_hit_state(previous_movement_state)

# Helper method to check if currently flapping (for animation system)
func is_flapping() -> bool:
	"""Returns true if eagle is currently in lifting state (flapping)"""
	return movement_state == MovementState.LIFTING
