extends RigidBody2D

class_name Fish

@export var spawn_x_offset: float = 200.0  # How far to the right of eagle to spawn
@export var spawn_x_variance: float = 100.0  # Random spawn position variance
@export var jump_force: float = 500.0
@export var jump_force_variation: float = 100.0  # Random variation in jump force
@export var horizontal_speed: float = 150.0  # Horizontal speed towards target
@export var lifetime: float = 5.0
@export var energy_value: float = 25.0  # Energy this fish provides when eaten


# Fish attachment variables
@export var fish_scale_when_caught: float = 0.8  # Make fish smaller when caught
@export var fish_offset_from_eagle: Vector2 = Vector2(0, 20)  # Position relative to eagle claws

# Fish drop variables
@export var drop_vertical_velocity: float = 150.0  # Initial downward velocity when dropped
@export var drop_backward_acceleration: float = -280.0  # Leftward acceleration to simulate falling behind eagle
@export var max_backward_velocity: float = -200.0  # Maximum leftward velocity
@export var screen_cleanup_margin: float = 100.0  # How far below screen to delete fish
@export var drop_cooldown_time: float = 1.0  # Time in seconds before fish can be caught again after being dropped

var is_caught: bool = false
var is_dropped: bool = false  # Track if fish was dropped by eagle
var can_be_caught: bool = true  # Whether fish can currently be caught
var eagle_reference: Eagle
var target_x: float
var start_position: Vector2
var screen_height: float  # Store screen height for cleanup

func setup_fish(eagle: Eagle, screen_height_value: float = 1080.0):
	"""Call this after spawning the fish to set the eagle reference and screen height"""
	eagle_reference = eagle
	screen_height = screen_height_value
	calculate_target_and_jump()

func _ready():
	# Set collision layers for proper detection
	collision_layer = 1  # Fish are on layer 1 for nest detection
	collision_mask = 0   # Fish don't need to detect other objects
	gravity_scale = 1.0
	
	# Get the detection area and connect signal
	var catch_area = $CatchArea
	catch_area.body_entered.connect(_on_catch_area_entered)
	
	# Set up catch area for nest detection
	catch_area.collision_layer = 1  # Same layer as fish body for consistent detection
	catch_area.collision_mask = 1   # CatchArea doesn't need to detect anything
	
	# Add to fish group for easy detection
	add_to_group("fish")
	
	# Set up lifetime timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_ended)
	timer.start()
	
	# Note: calculate_target_and_jump() will be called after setup_fish() is called

func calculate_target_and_jump():
	# Store starting position
	start_position = global_position
	
	# Fish should jump TOWARDS the eagle, not away from it
	target_x = eagle_reference.global_position.x
	

	
	# Calculate direction to target (should be LEFT since fish spawns to the right)
	var direction = 1 if target_x > global_position.x else -1
	var horizontal_velocity = horizontal_speed * direction
	
	# Apply random variation to jump force
	var variation = randf_range(-jump_force_variation, jump_force_variation)
	var actual_jump_force = jump_force + variation
	
	# Make sure jump force doesn't go below a minimum
	actual_jump_force = max(actual_jump_force, 200.0)  # Minimum jump force
	
	# Apply the jump with calculated horizontal speed and varied jump force
	linear_velocity = Vector2(horizontal_velocity, -actual_jump_force)
	


func _physics_process(delta):
	# If fish is caught, follow the eagle
	if is_caught and eagle_reference:
		# Disable physics and follow eagle
		freeze = true
		
		# Get eagle's rotation and position
		var eagle_rotation = eagle_reference.rotation
		var eagle_position = eagle_reference.global_position
		
		# Rotate the offset vector by eagle's rotation
		var rotated_offset = fish_offset_from_eagle.rotated(eagle_rotation)
		
		# Set fish position using rotated offset
		global_position = eagle_position + rotated_offset
		
		# Set fish rotation to match eagle's rotation
		rotation = eagle_rotation
		
		return
	
	# Apply gradual leftward acceleration for dropped fish
	if is_dropped and not freeze:
		# Gradually increase leftward velocity to simulate falling behind eagle
		linear_velocity.x += drop_backward_acceleration * delta
		# Clamp to maximum backward velocity
		linear_velocity.x = max(linear_velocity.x, max_backward_velocity)
	
	# Check if dropped fish should be cleaned up when it goes below screen
	if is_dropped and global_position.y > screen_height + screen_cleanup_margin:

		queue_free()
		return


func _on_catch_area_entered(body):
	# Check if the eagle entered the catch area and fish can be caught
	if body is Eagle and not is_caught and can_be_caught:
		catch_fish(body)

func catch_fish(eagle):
	# First check if eagle can catch this fish
	var successfully_caught = false
	if eagle.has_method("catch_fish"):
		successfully_caught = eagle.catch_fish(self)  # Eagle returns true if it can catch
	
	# Only proceed if eagle successfully caught the fish
	if successfully_caught:
		is_caught = true
		
		# Make fish smaller and attach to eagle
		scale = Vector2(fish_scale_when_caught, fish_scale_when_caught)
		
		# Disable physics
		freeze = true
		
		# Disable collision detection for caught fish
		var catch_area = $CatchArea
		catch_area.set_deferred("monitoring", false)
		


func release_fish():
	"""Called when eagle releases/drops the fish"""
	is_caught = false
	is_dropped = true  # Mark as dropped for cleanup tracking
	freeze = false
	
	# Temporarily disable catching to prevent immediate re-catch
	can_be_caught = false
	
	# Re-enable collision detection but fish won't be catchable until cooldown ends
	var catch_area = $CatchArea
	catch_area.set_deferred("monitoring", true)
	
	# Start cooldown timer to re-enable catching
	var cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.wait_time = drop_cooldown_time
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_drop_cooldown_ended)
	cooldown_timer.start()
	
	# Reset scale
	scale = Vector2(1.0, 1.0)
	
	# Apply initial drop physics - starts falling mostly straight down
	# Minimal initial horizontal velocity, leftward acceleration will be applied over time
	var initial_horizontal_velocity = randf_range(-20.0, 10.0)  # Small random variation
	linear_velocity = Vector2(initial_horizontal_velocity, drop_vertical_velocity)
	
	# Add some rotation for visual effect
	angular_velocity = randf_range(-5.0, 5.0)
	


func _on_drop_cooldown_ended():
	"""Called when the drop cooldown timer expires - re-enable catching"""
	can_be_caught = true


func _on_lifetime_ended():
	# Remove fish if not caught within lifetime
	if not is_caught:

		queue_free()

# Static method to spawn fish at bottom of screen
static func spawn_fish_at_bottom(scene_tree: SceneTree, fish_scene: PackedScene, eagle: Eagle, screen_width: float, viewport_height: float):
	var fish = fish_scene.instantiate()
	
	# Check if the fish is actually a Fish instance
	if not fish is Fish:

		fish.queue_free()
		return null
	

	
	# Spawn fish to the RIGHT of the eagle
	# Use spawn_x_offset to determine how far to the right of eagle to spawn
	var spawn_x = eagle.global_position.x + fish.spawn_x_offset
	
	# Add some random variation to spawn position
	spawn_x += randf_range(-fish.spawn_x_variance/2, fish.spawn_x_variance/2)
	
	# Make sure fish doesn't spawn off-screen
	spawn_x = min(spawn_x, screen_width - 50)
	
	# Spawn fish BELOW the bottom of the screen
	var spawn_y = viewport_height + randf_range(50, 150)  # 50-150 pixels below screen bottom
	

	
	fish.global_position = Vector2(spawn_x, spawn_y)
	
	# Add to scene
	scene_tree.current_scene.add_child(fish)
	
	# Setup the fish with eagle reference and screen height
	fish.setup_fish(eagle, viewport_height)
	
	return fish
