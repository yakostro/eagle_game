# Default movement controller - preserves original eagle movement behavior
# This contains the exact same movement logic from the original eagle.gd

class_name DefaultMovementController
extends BaseMovementController

# Physics constants - moved from eagle.gd
@export var max_up_velocity: float = -400.0
@export var max_down_velocity: float = 500.0
@export var lift_acceleration: float = 2000.0
@export var dive_acceleration: float = 3000.0
@export var drag: float = 500.0
@export var neutral_drag: float = 800.0
@export var neutral_threshold: float = 5.0

# Rotation constants - moved from eagle.gd
@export var max_rotation_up: float = -45.0
@export var max_rotation_down: float = 45.0
@export var rotation_speed: float = 3.0
@export var min_speed_for_rotation: float = 50.0
@export var max_speed_for_rotation: float = 1000.0

# Hit state tracking
var previous_movement_state: MovementState = MovementState.GLIDING

func _init(body: CharacterBody2D):
	super._init(body)

func handle_input_and_update_state():
	"""Handle input and determine movement state - original logic from eagle.gd"""
	var new_state = determine_movement_state()
	
	if new_state != movement_state:
		set_movement_state(new_state)

func determine_movement_state() -> MovementState:
	"""Determine movement state based on input - original logic from eagle.gd"""
	if Input.is_action_pressed("move_up"):
		return MovementState.LIFTING
	elif Input.is_action_pressed("move_down"):
		var current_velocity = get_velocity()
		if current_velocity.y > 200.0:  # Fast downward = diving
			return MovementState.DIVING
		else:
			return MovementState.LIFTING
	else:
		return MovementState.GLIDING

func apply_movement_physics(delta: float):
	"""Apply physics based on current state - original logic from eagle.gd"""
	var current_velocity = get_velocity()
	
	match movement_state:
		MovementState.LIFTING:
			current_velocity = apply_lifting_physics(current_velocity, delta)
		MovementState.DIVING:
			current_velocity = apply_diving_physics(current_velocity, delta)
		MovementState.GLIDING:
			current_velocity = apply_gliding_physics(current_velocity, delta)
		MovementState.HIT:
			current_velocity = apply_hit_physics(current_velocity, delta)
	
	# Clamp velocity - original logic from eagle.gd
	current_velocity.y = clamp(current_velocity.y, max_up_velocity, max_down_velocity)
	
	set_velocity(current_velocity)

func apply_lifting_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply lifting physics - original logic from eagle.gd"""
	if Input.is_action_pressed("move_up"):
		velocity.y -= lift_acceleration * delta
	elif Input.is_action_pressed("move_down"):
		velocity.y += dive_acceleration * delta
	return velocity

func apply_diving_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply diving physics - original logic from eagle.gd"""
	# Enhanced downward acceleration for diving
	velocity.y += dive_acceleration * 1.5 * delta
	return velocity

func apply_gliding_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply gliding physics - original logic from eagle.gd"""
	# Gentle return to neutral during gliding
	if velocity.y > neutral_threshold:
		velocity.y -= neutral_drag * delta
	elif velocity.y < -neutral_threshold:
		velocity.y += neutral_drag * delta
	else:
		velocity.y = 0.0
	return velocity

func apply_hit_physics(velocity: Vector2, delta: float) -> Vector2:
	"""Apply hit physics - original logic from eagle.gd"""
	# During hit, eagle maintains momentum but doesn't respond to input
	# Apply gentle drag to slow down over time
	if velocity.y > neutral_threshold:
		velocity.y -= drag * delta
	elif velocity.y < -neutral_threshold:
		velocity.y += drag * delta
	return velocity

func update_rotation(delta: float):
	"""Update rotation based on velocity - original logic from eagle.gd"""
	var velocity = get_velocity()
	var speed = velocity.length()
	var target_rotation = 0.0
	
	if speed > min_speed_for_rotation:
		var speed_ratio = clamp((speed - min_speed_for_rotation) / (max_speed_for_rotation - min_speed_for_rotation), 0.0, 1.0)
		
		if velocity.y < 0:
			target_rotation = -speed_ratio * abs(max_rotation_up)
		elif velocity.y > 0:
			target_rotation = speed_ratio * max_rotation_down
	
	var current_rotation_deg = rad_to_deg(get_rotation())
	var new_rotation_deg = lerp(current_rotation_deg, target_rotation, rotation_speed * delta)
	set_rotation(deg_to_rad(new_rotation_deg))

func handle_hit_state():
	"""Handle hit state logic - called by eagle when hit occurs"""
	if movement_state != MovementState.HIT:
		previous_movement_state = movement_state
	force_hit_state()

func restore_from_hit_state():
	"""Restore from hit state to previous state"""
	end_hit_state(previous_movement_state)
