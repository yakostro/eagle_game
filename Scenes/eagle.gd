extends CharacterBody2D

# State machine enum
enum EagleState {GLIDING, FLAPPING}

# Physics constants
const MAX_UP_VELOCITY = -600.0  # Max upward speed
const MAX_DOWN_VELOCITY = 800.0  # Max downward speed
const GRAVITY_SCALE = 0.1       # Slow gravity for gentle descent
const LIFT_ACCELERATION = 11000.0  # Strong flap
const DIVE_ACCELERATION = 12000.0  # Strong dive
const DRAG = 500.0             # Counter-force to stop going up too far

# Rotation constants
const MAX_ROTATION_UP = -45.0   # Max rotation when flying up (degrees)
const MAX_ROTATION_DOWN = 45.0  # Max rotation when falling down (degrees)
const ROTATION_SPEED = 3.0      # How fast the rotation changes
const MIN_SPEED_FOR_ROTATION = 50.0  # Minimum speed to start rotating
const MAX_SPEED_FOR_ROTATION = 1000.0  # Speed at which max rotation is reached

# State transition constants
const STATE_TRANSITION_HYSTERESIS = 10.0  # Prevents rapid state switching

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state: EagleState = EagleState.GLIDING
var previous_velocity_y: float = 0.0

func _ready():
	# Initialize with gliding state (default)
	change_state(EagleState.GLIDING)

func _physics_process(delta):
	# Determine target state based on input and velocity
	var target_state = determine_target_state()
	
	# Change state if needed
	if target_state != current_state:
		change_state(target_state)
	
	# Apply state-specific physics
	apply_state_physics(delta)
	
	# Update rotation based on actual speed
	update_rotation(delta)
	
	# Apply movement
	move_and_slide()
	
	# Store previous velocity for state transitions
	previous_velocity_y = velocity.y

func determine_target_state() -> EagleState:
	# Check for flapping state first (input should always override other states)
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		return EagleState.FLAPPING
	
	# Check for flapping state based on upward motion
	if velocity.y < -STATE_TRANSITION_HYSTERESIS:
		return EagleState.FLAPPING
	
	# Default to gliding (downward motion or no input)
	return EagleState.GLIDING

func change_state(new_state: EagleState):
	if new_state == current_state:
		return
	
	current_state = new_state
	
	# Update animation based on new state
	match current_state:
		EagleState.FLAPPING:
			if $AnimatedSprite2D.animation != "flap":
				$AnimatedSprite2D.play("flap")
		EagleState.GLIDING:
			if $AnimatedSprite2D.animation != "glide":
				$AnimatedSprite2D.play("glide")

func apply_state_physics(delta):
	match current_state:
		EagleState.FLAPPING:
			apply_flapping_physics(delta)
		EagleState.GLIDING:
			apply_gliding_physics(delta)
	
	# Apply gravity to all states
	velocity.y += gravity * GRAVITY_SCALE * delta
	
	# Clamp vertical velocity between max up/down
	velocity.y = clamp(velocity.y, MAX_UP_VELOCITY, MAX_DOWN_VELOCITY)



func apply_flapping_physics(delta):
	# Apply upward force when input is pressed
	if Input.is_action_pressed("move_up") and velocity.y > MAX_UP_VELOCITY:
		velocity.y -= LIFT_ACCELERATION * delta
	# Apply downward force when input is pressed
	elif Input.is_action_pressed("move_down") and velocity.y < MAX_DOWN_VELOCITY:
		velocity.y += DIVE_ACCELERATION * delta
	else:
		# No input: apply drag to upward motion to transition to gliding
		if velocity.y < 0.0:
			velocity.y += DRAG * delta

func apply_gliding_physics(delta):
	# In gliding state, allow dive input for faster descent
	if Input.is_action_pressed("move_down") and velocity.y < MAX_DOWN_VELOCITY:
		velocity.y += DIVE_ACCELERATION * 0.5 * delta
	# Allow flap input to transition back to flying
	elif Input.is_action_pressed("move_up") and velocity.y > MAX_UP_VELOCITY:
		velocity.y -= LIFT_ACCELERATION * delta
	else:
		# Natural gliding: let gravity handle descent
		# Apply minimal drag to prevent excessive speed
		if velocity.y > 200.0:
			velocity.y -= DRAG * 0.2 * delta

func update_rotation(delta):
	# Calculate actual speed (magnitude of velocity)
	var speed = velocity.length()
	
	# Calculate target rotation based on speed and direction
	var target_rotation = 0.0
	
	if speed > MIN_SPEED_FOR_ROTATION:
		# Calculate speed ratio (0 to 1) based on current speed
		var speed_ratio = clamp((speed - MIN_SPEED_FOR_ROTATION) / (MAX_SPEED_FOR_ROTATION - MIN_SPEED_FOR_ROTATION), 0.0, 1.0)
		
		# Determine rotation direction based on vertical velocity
		if velocity.y < 0:  # Flying up
			target_rotation = -speed_ratio * abs(MAX_ROTATION_UP)
		elif velocity.y > 0:  # Falling down
			target_rotation = speed_ratio * MAX_ROTATION_DOWN
		# If velocity.y is 0, target_rotation remains 0 (level flight)
	
	# Smoothly interpolate current rotation to target rotation
	var current_rotation_deg = rad_to_deg(rotation)
	var new_rotation_deg = lerp(current_rotation_deg, target_rotation, ROTATION_SPEED * delta)
	rotation = deg_to_rad(new_rotation_deg)
