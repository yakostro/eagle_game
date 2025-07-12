extends CharacterBody2D

@onready var eagle = $"."
@onready var label = $"../CanvasLayer/Label"


# State machine enum
enum EagleState {GLIDING, CHANGING_POSITION}

# Physics constants
const MAX_UP_VELOCITY = -600.0  # Max upward speed
const MAX_DOWN_VELOCITY = 800.0  # Max downward speed
const LIFT_ACCELERATION = 11000.0  # Strong flap
const DIVE_ACCELERATION = 12000.0  # Strong dive
const DRAG = 500.0             # Counter-force to stop going up too far
const NEUTRAL_DRAG = 800.0     # Force to return to neutral position
const NEUTRAL_THRESHOLD = 5.0  # Speed threshold for neutral state

# Animation constants
const GLIDE_FLAP_INTERVAL = 3.0  # Seconds between glide flaps
const GLIDE_FLAP_CYCLES = 2      # Number of flap cycles during glide flap

# Rotation constants
const MAX_ROTATION_UP = -45.0   # Max rotation when flying up (degrees)
const MAX_ROTATION_DOWN = 45.0  # Max rotation when falling down (degrees)
const ROTATION_SPEED = 3.0      # How fast the rotation changes
const MIN_SPEED_FOR_ROTATION = 50.0  # Minimum speed to start rotating
const MAX_SPEED_FOR_ROTATION = 1000.0  # Speed at which max rotation is reached

# State transition constants
const STATE_TRANSITION_HYSTERESIS = 10.0  # Prevents rapid state switching

var current_state: EagleState = EagleState.GLIDING
var previous_velocity_y: float = 0.0
var glide_flap_timer: float = 0.0
var is_glide_flapping: bool = false
var glide_flap_cycle_count: int = 0

func _ready():
	# Initialize with gliding state (default)
	change_state(EagleState.GLIDING)


func update_UI():
	label.text = str(EagleState.keys()[current_state])


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
	
	update_UI()
	
	# Store previous velocity for state transitions
	previous_velocity_y = velocity.y

func determine_target_state() -> EagleState:
	# Check for changing position state first (input should always override other states)
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		return EagleState.CHANGING_POSITION
	
	# Default to gliding (no input or any motion)
	return EagleState.GLIDING

func change_state(new_state: EagleState):
	if new_state == current_state:
		return
	
	current_state = new_state
	
	# Set animation based on new state
	match current_state:
		EagleState.CHANGING_POSITION:
			if $AnimatedSprite2D.animation != "flap":
				$AnimatedSprite2D.play("flap")
		EagleState.GLIDING:
			if $AnimatedSprite2D.animation != "glide":
				$AnimatedSprite2D.play("glide")
	
	# Reset glide flap timer when entering gliding state
	if new_state == EagleState.GLIDING:
		glide_flap_timer = 0.0
		is_glide_flapping = false
	

func apply_state_physics(delta):
	match current_state:
		EagleState.CHANGING_POSITION:
			apply_flapping_physics(delta)
		EagleState.GLIDING:
			apply_gliding_physics(delta)
	
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
		# No input: apply drag to return to neutral
		if velocity.y < 0.0:
			velocity.y += DRAG * delta
		elif velocity.y > 0.0:
			velocity.y -= DRAG * delta

func apply_gliding_physics(delta):
	# Handle glide flap animation timer
	glide_flap_timer += delta
	
	# Check if it's time for a glide flap
	if glide_flap_timer >= GLIDE_FLAP_INTERVAL and not is_glide_flapping:
		start_glide_flap()
	
	# In gliding state, allow dive input for faster descent
	if Input.is_action_pressed("move_down") and velocity.y < MAX_DOWN_VELOCITY:
		velocity.y += DIVE_ACCELERATION * 0.5 * delta
	# Allow flap input to transition back to flying
	elif Input.is_action_pressed("move_up") and velocity.y > MAX_UP_VELOCITY:
		velocity.y -= LIFT_ACCELERATION * delta
	else:
		# No input: apply drag to gradually return to neutral
		if velocity.y > NEUTRAL_THRESHOLD:
			velocity.y -= NEUTRAL_DRAG * delta
		elif velocity.y < -NEUTRAL_THRESHOLD:
			velocity.y += NEUTRAL_DRAG * delta
		else:
			# Very close to neutral, stop movement
			velocity.y = 0.0

func start_glide_flap():
	is_glide_flapping = true
	glide_flap_timer = 0.0
	glide_flap_cycle_count = 0
	
	# Play the flap animation for 2 cycles
	if $AnimatedSprite2D.animation != "flap":
		$AnimatedSprite2D.play("flap")
	
	# Wait for 2 full animation cycles to complete
	while glide_flap_cycle_count < GLIDE_FLAP_CYCLES:
		await $AnimatedSprite2D.animation_finished
		glide_flap_cycle_count += 1
		
		# If we haven't completed all cycles, restart the flap animation
		if glide_flap_cycle_count < GLIDE_FLAP_CYCLES:
			$AnimatedSprite2D.play("flap")
	
	# Return to glide animation after completing all cycles
	if current_state == EagleState.GLIDING:
		$AnimatedSprite2D.play("glide")
		is_glide_flapping = false

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
