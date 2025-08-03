class_name EnemyBird
extends CharacterBody2D

# Movement configuration variables (for balancing)
@export var base_speed: float = 800.0  # Base movement speed
@export var acceleration: float = 1500.0  # How fast bird accelerates
@export var curve_strength: float = 5.0  # How much the bird curves towards eagle
@export var direction_change_speed: float = 5  # How fast bird can change direction when eagle moves
@export var max_direction_change_rate: float = 90.0  # Max degrees per second for direction change
@export var hit_distance: float = 50.0  # Distance at which bird hits eagle

# References
var eagle_target: Eagle = null  # Reference to the eagle
var screen_size: Vector2
var initial_target_y: float  # Eagle's Y position when bird was spawned

# Movement state
var current_velocity: Vector2 = Vector2.ZERO
var target_direction: Vector2 = Vector2.LEFT  # Initial direction towards left
var spawn_position: Vector2
var has_hit_eagle: bool = false  # Prevent multiple hits from same bird

func _ready():
	# Get screen size for boundary checking
	screen_size = get_viewport().get_visible_rect().size
	
	# Find the eagle in the scene
	eagle_target = get_tree().get_first_node_in_group("eagle")
	if not eagle_target:
		# Fallback: try to find Eagle by class name
		var eagles = get_tree().get_nodes_in_group("eagle")
		if eagles.size() > 0:
			eagle_target = eagles[0] as Eagle
	
	if eagle_target:
		initial_target_y = eagle_target.global_position.y
		print("Enemy bird locked onto eagle at Y: ", initial_target_y)
	else:
		print("Warning: Enemy bird couldn't find eagle target!")
	
	# Store spawn position for trajectory calculation
	spawn_position = global_position

func _physics_process(delta):
	# Update movement
	update_target_direction(delta)
	apply_movement(delta)
	
	# Check for collision with eagle
	check_eagle_collision()
	
	# Check if bird has moved off screen (left side)
	if global_position.x < -100:  # Give some buffer beyond screen edge
		queue_free()  # Remove from game

func check_eagle_collision():
	if not eagle_target or has_hit_eagle:
		return
	
	# Check distance to eagle for hit detection (no physical collision)
	var distance_to_eagle = global_position.distance_to(eagle_target.global_position)
	
	if distance_to_eagle <= hit_distance:
		hit_eagle(eagle_target)

func hit_eagle(eagle: Eagle):
	print("Enemy bird hit the eagle!")
	
	# Mark that this bird has hit the eagle (prevent multiple hits)
	has_hit_eagle = true
	
	# Tell the eagle it was hit by an enemy
	eagle.hit_by_enemy(self)
	
	# Continue flying in current direction (no more targeting)
	eagle_target = null  # Stop following the eagle
	
	# Note: Bird will continue with current velocity and fly off screen

func update_target_direction(delta):
	if not eagle_target:
		return
	
	var eagle_pos = eagle_target.global_position
	
	# If bird has passed the eagle's X position, stop adjusting trajectory
	if global_position.x <= eagle_pos.x:
		return
	
	# Always move left (X direction is constant)
	var desired_direction = Vector2(-1.0, 0.0)
	
	# Only adjust Y direction to target eagle's Y position
	var y_distance = eagle_pos.y - global_position.y
	var y_direction = sign(y_distance)
	
	# Calculate how much to curve towards eagle Y position
	var y_strength = min(abs(y_distance) / 200.0, 1.0) * curve_strength * 0.1
	desired_direction.y = y_direction * y_strength
	
	# Smoothly adjust current target direction
	var blend_factor = direction_change_speed * delta
	target_direction = target_direction.lerp(desired_direction.normalized(), blend_factor)

func apply_movement(delta):
	# Accelerate towards target direction
	var desired_velocity = target_direction * base_speed
	current_velocity = current_velocity.move_toward(desired_velocity, acceleration * delta)
	
	# Move directly without collision detection (pass through everything)
	global_position += current_velocity * delta
