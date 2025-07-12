extends CharacterBody2D

const MAX_UP_VELOCITY = -600.0  # Max upward speed
const MAX_DOWN_VELOCITY = 800.0  # Max downward speed
const GRAVITY_SCALE = 0.1       # Slow gravity for gentle descent
const LIFT_ACCELERATION = 11000.0  # Strong flap
const DIVE_ACCELERATION = 12000.0  # Strong dive
const DRAG = 500.0             # Counter-force to stop going up too far
const MAX_ROTATION_UP = -45.0   # Max rotation when flying up (degrees)
const MAX_ROTATION_DOWN = 45.0  # Max rotation when falling down (degrees)
const ROTATION_SPEED = 3.0      # How fast the rotation changes
const MIN_SPEED_FOR_ROTATION = 50.0  # Minimum speed to start rotating
const MAX_SPEED_FOR_ROTATION = 1000.0  # Speed at which max rotation is reached
const FLY_ANIMATION_THRESHOLD = 7.0  # Rotation threshold to trigger fly animation (degrees)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Pressing UP: apply upward force
	if Input.is_action_pressed("move_up") and velocity.y > MAX_UP_VELOCITY:
		velocity.y -= LIFT_ACCELERATION * delta
	# Pressing DOWN: apply downward force
	elif Input.is_action_pressed("move_down") and velocity.y < MAX_DOWN_VELOCITY:
		velocity.y += DIVE_ACCELERATION * delta
	else:
		# Not pressing UP or DOWN: apply drag only to upward motion
		if velocity.y < 0.0:
			velocity.y += DRAG * delta  # Reduce upward velocity
		# No drag for downward motion - let gravity handle it naturally

	# Apply gentle gravity
	velocity.y += gravity * GRAVITY_SCALE * delta
	
	# Clamp vertical velocity between max up/down
	velocity.y = clamp(velocity.y, MAX_UP_VELOCITY, MAX_DOWN_VELOCITY)

	# Update rotation based on actual speed
	update_rotation(delta)
	
	update_animation()

	move_and_slide()

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


func update_animation():
	# Get current rotation in degrees
	var current_rotation_deg = rad_to_deg(rotation)
	
	# Play fly animation when rotation is less than negative threshold (going up)
	if current_rotation_deg < -FLY_ANIMATION_THRESHOLD:
		if $AnimatedSprite2D.animation != "fly":
			$AnimatedSprite2D.play("fly")
	else:
		# When rotation is at threshold or higher, play glide animation (going down or level)
		if $AnimatedSprite2D.animation != "glide":
			$AnimatedSprite2D.play("glide")
