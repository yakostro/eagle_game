extends RigidBody2D

class_name Fish

@export var spawn_x_offset: float = 200.0  # How far to the right of eagle to spawn
@export var jump_force: float = 500.0
@export var jump_force_variation: float = 100.0  # Random variation in jump force
@export var horizontal_speed: float = 150.0  # Horizontal speed towards target
@export var lifetime: float = 5.0
@export var spawn_x_variance: float = 100.0  # Random spawn position variance

var is_caught: bool = false
var eagle_reference: Eagle
var target_x: float
var start_position: Vector2

func setup_fish(eagle: Eagle):
	"""Call this after spawning the fish to set the eagle reference"""
	eagle_reference = eagle
	calculate_target_and_jump()

func _ready():
	# Disable physical collisions but keep gravity
	collision_layer = 0
	collision_mask = 0
	gravity_scale = 1.0
	
	# Get the detection area and connect signal
	var catch_area = $CatchArea
	catch_area.body_entered.connect(_on_catch_area_entered)
	
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
	
	# DEBUG: Print eagle and target positions
	print("Eagle position: ", eagle_reference.global_position)
	print("Fish start position: ", global_position)
	print("Target X (eagle): ", target_x)
	
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
	
	# DEBUG: Print velocity and variation
	print("Direction: ", direction, " (", "right" if direction > 0 else "left", ")")
	print("Jump force variation: ", variation, " (base: ", jump_force, " final: ", actual_jump_force, ")")
	print("Fish velocity: ", linear_velocity)
	print("Fish jumping from X:", global_position.x, " to target X:", target_x)

func _physics_process(delta):
	# Optional: Debug visualization (remove in final game)
	if is_caught:
		return
		
	# Check if fish has passed the target X coordinate
	if global_position.x >= target_x:
		print("Fish passed target X coordinate at Y:", global_position.y)

func _on_catch_area_entered(body):
	# Check if the eagle entered the catch area
	if body is Eagle and not is_caught:
		catch_fish(body)

func catch_fish(eagle):
	is_caught = true
	
	# Notify the eagle that it caught a fish
	if eagle.has_method("catch_fish"):
		eagle.catch_fish()
	else:
		print("Eagle caught a fish!")
	
	# Remove the fish from the scene
	queue_free()

func _on_lifetime_ended():
	# Remove fish if not caught within lifetime
	if not is_caught:
		print("Fish expired at position:", global_position)
		queue_free()

# Static method to spawn fish at bottom of screen
static func spawn_fish_at_bottom(scene_tree: SceneTree, fish_scene: PackedScene, eagle: Eagle, screen_width: float, screen_height: float):
	var fish = fish_scene.instantiate()
	
	# Check if the fish is actually a Fish instance
	if not fish is Fish:
		print("Error: Fish scene doesn't have Fish script attached!")
		fish.queue_free()
		return null
	
	# DEBUG: Print screen size
	print("Screen size: ", screen_width, "x", screen_height)
	
	# Spawn fish to the RIGHT of the eagle
	# Use spawn_x_offset to determine how far to the right of eagle to spawn
	var spawn_x = eagle.global_position.x + fish.spawn_x_offset
	
	# Add some random variation to spawn position
	spawn_x += randf_range(-fish.spawn_x_variance/2, fish.spawn_x_variance/2)
	
	# Make sure fish doesn't spawn off-screen
	spawn_x = min(spawn_x, screen_width - 50)
	
	var spawn_y = min(screen_height - 100, 500)  # Don't spawn too far down
	
	# If screen height seems too large, use a fixed position
	if screen_height > 1000:
		spawn_y = 400  # Fixed position for very large screens
	
	# DEBUG: Print spawn position
	print("Eagle at X: ", eagle.global_position.x)
	print("Spawning fish at: ", spawn_x, ", ", spawn_y, " (", spawn_x - eagle.global_position.x, " pixels to the right of eagle)")
	
	fish.global_position = Vector2(spawn_x, spawn_y)
	
	# Add to scene
	scene_tree.current_scene.add_child(fish)
	
	# Setup the fish with eagle reference
	fish.setup_fish(eagle)
	
	return fish
