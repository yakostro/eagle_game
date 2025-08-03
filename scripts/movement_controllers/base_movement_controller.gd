# Base abstract class for eagle movement controllers
# This defines the interface that all movement controllers must implement

class_name BaseMovementController
extends Node

# Movement states - same as before but now owned by movement controller
enum MovementState { GLIDING, LIFTING, DIVING, HIT }

# Current movement state
var movement_state: MovementState = MovementState.GLIDING

# Reference to the eagle body for physics
var eagle_body: CharacterBody2D

# Signals for movement state changes
signal movement_state_changed(old_state: MovementState, new_state: MovementState)

func _init(body: CharacterBody2D):
	"""Initialize the movement controller with reference to eagle body"""
	eagle_body = body
	if eagle_body == null:
		print("ERROR: Eagle body reference is null!")

func _ready():
	set_physics_process(true)

# ===== ABSTRACT METHODS - Must be implemented by subclasses =====

func handle_input_and_update_state():
	"""Handle input and determine what the movement state should be"""
	push_error("handle_input_and_update_state() must be implemented by subclass")

func apply_movement_physics(_delta: float):
	"""Apply physics based on current movement state"""
	push_error("apply_movement_physics() must be implemented by subclass")

func update_rotation(_delta: float):
	"""Update eagle rotation based on movement"""
	push_error("update_rotation() must be implemented by subclass")

func handle_hit_state():
	"""Handle special physics during hit state"""
	push_error("handle_hit_state() must be implemented by subclass")

# ===== COMMON METHODS - Shared by all movement controllers =====

func _physics_process(delta):
	"""Main physics update - calls abstract methods in proper order"""
	if eagle_body == null:
		return
	
	# 1. Handle input and determine movement state (unless in HIT state)
	if movement_state != MovementState.HIT:
		handle_input_and_update_state()
	
	# 2. Apply movement physics
	apply_movement_physics(delta)
	
	# 3. Update rotation
	update_rotation(delta)

func set_movement_state(new_state: MovementState):
	"""Set movement state and emit signal if changed"""
	if new_state != movement_state:
		var old_state = movement_state
		movement_state = new_state
		movement_state_changed.emit(old_state, new_state)
		print("Movement Controller: State changed from ", MovementState.keys()[old_state], " to ", MovementState.keys()[new_state])

func get_movement_state() -> MovementState:
	"""Get current movement state"""
	return movement_state

func force_hit_state():
	"""Force movement state to HIT (called by eagle when hit)"""
	set_movement_state(MovementState.HIT)

func end_hit_state(return_to_state: MovementState = MovementState.GLIDING):
	"""End hit state and return to specified state"""
	set_movement_state(return_to_state)

func get_velocity() -> Vector2:
	"""Get current velocity from eagle body"""
	if eagle_body:
		return eagle_body.velocity
	return Vector2.ZERO

func set_velocity(new_velocity: Vector2):
	"""Set velocity on eagle body"""
	if eagle_body:
		eagle_body.velocity = new_velocity

func get_rotation() -> float:
	"""Get current rotation from eagle body"""
	if eagle_body:
		return eagle_body.rotation
	return 0.0

func set_rotation(new_rotation: float):
	"""Set rotation on eagle body"""
	if eagle_body:
		eagle_body.rotation = new_rotation
