extends Node2D

class_name FishSpawner

@export var fish_scene: PackedScene  # Drag your Fish.tscn here
@export var spawn_interval: float = 5.0  # Seconds between spawns
@export var spawn_interval_variance: float = 2.0  # Random variation in timing
@export var min_spawn_interval: float = 2.0  # Minimum time between spawns
@export var eagle_reference: Eagle

# Fish boost before nest system
@export_group("Pre-Nest Fish Boost")
@export var boost_enabled: bool = true  # Enable fish boost before nest spawns
@export var boost_trigger_obstacles: int = 2  # How many obstacles before nest to start boost
@export var boost_spawn_interval: float = 1.5  # Spawn interval during boost (faster)
@export var boost_duration: float = 8.0  # How long boost lasts (seconds)
@export var min_fish_guaranteed: int = 2  # Minimum fish to spawn during boost period

var spawn_timer: Timer
var screen_size: Vector2
var nest_spawner: NestSpawner
var is_boosting: bool = false
var boost_timer: Timer
var fish_spawned_during_boost: int = 0

func _ready():
	# Find the eagle (you can also drag and drop this in the inspector)
	eagle_reference = get_tree().current_scene.find_child("Eagle", true, false)
	if not eagle_reference:
		print("Warning: No eagle found! Make sure your eagle node is named 'Eagle'")
		return
	
	# Find nest spawner for boost coordination
	nest_spawner = get_tree().current_scene.find_child("NestSpawner", true, false)
	if nest_spawner and boost_enabled:
		nest_spawner.nest_incoming.connect(_on_nest_incoming)
		print("🐟 FishSpawner: Connected to NestSpawner for pre-nest boost")
	elif boost_enabled:
		print("⚠️  FishSpawner: Boost enabled but no NestSpawner found")
	
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# Create boost timer
	boost_timer = Timer.new()
	boost_timer.one_shot = true
	add_child(boost_timer)
	boost_timer.timeout.connect(_on_boost_timeout)
	
	print("🐟 FishSpawner initialized with boost settings:")
	print("   - Boost enabled: ", boost_enabled)
	print("   - Trigger obstacles: ", boost_trigger_obstacles)
	print("   - Boost interval: ", boost_spawn_interval, "s")
	print("   - Boost duration: ", boost_duration, "s")
	print("   - Min guaranteed fish: ", min_fish_guaranteed)
	
func _on_spawn_timer_timeout():
	spawn_fish()
	
	# Count fish spawned during boost
	if is_boosting:
		fish_spawned_during_boost += 1
	
	# Set next spawn interval based on boost state
	var base_interval = boost_spawn_interval if is_boosting else spawn_interval
	var variance = spawn_interval_variance * 0.5 if is_boosting else spawn_interval_variance
	
	var next_interval = base_interval + randf_range(-variance, variance)
	next_interval = max(next_interval, min_spawn_interval)
	spawn_timer.wait_time = next_interval
	spawn_timer.start()

func spawn_fish():
	if not fish_scene:
		print("Error: No fish scene assigned to spawner!")
		return
	
	if not eagle_reference:
		print("Error: No eagle reference available!")
		return
	
	# Use the Fish's static spawn method with eagle reference
	var _fish = Fish.spawn_fish_at_bottom(get_tree(), fish_scene, eagle_reference, screen_size.x, screen_size.y)

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)

# Method to manually spawn fish (for testing)
func spawn_fish_now():
	spawn_fish()

# Method to manually test boost system (for debugging)
func test_boost_system():
	print("🧪 Testing fish boost system...")
	start_fish_boost()
	await get_tree().create_timer(3.0).timeout  # Wait 3 seconds
	print("🧪 Force ending boost for test...")
	end_fish_boost()

# Pre-nest boost system
func _on_nest_incoming(obstacles_remaining: int):
	"""Called when nest is incoming - start fish boost if needed"""
	if not boost_enabled:
		return
	
	if obstacles_remaining <= boost_trigger_obstacles and not is_boosting:
		start_fish_boost()

func start_fish_boost():
	"""Start boosted fish spawning before nest appears"""
	if is_boosting:
		return
	
	is_boosting = true
	fish_spawned_during_boost = 0
	
	print("🐟 FISH BOOST STARTED! Interval: ", boost_spawn_interval, "s for ", boost_duration, "s")
	
	# Restart spawn timer with boost interval
	spawn_timer.stop()
	spawn_timer.wait_time = boost_spawn_interval
	spawn_timer.start()
	
	# Start boost duration timer
	boost_timer.wait_time = boost_duration
	boost_timer.start()
	
	# Immediately spawn a fish to give instant opportunity
	spawn_fish()
	fish_spawned_during_boost += 1

func _on_boost_timeout():
	"""Called when boost duration ends"""
	end_fish_boost()

func end_fish_boost():
	"""End boosted fish spawning and return to normal"""
	if not is_boosting:
		return
	
	is_boosting = false
	
	print("🐟 Fish boost ended. Spawned ", fish_spawned_during_boost, " fish during boost")
	
	# Ensure minimum fish were spawned
	if fish_spawned_during_boost < min_fish_guaranteed:
		var missing_fish = min_fish_guaranteed - fish_spawned_during_boost
		print("🐟 Spawning ", missing_fish, " additional fish to meet minimum guarantee")
		for i in range(missing_fish):
			spawn_fish()
			await get_tree().create_timer(0.5).timeout  # Small delay between guaranteed spawns
	
	# Return to normal spawn timing
	spawn_timer.stop()
	var normal_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
	normal_interval = max(normal_interval, min_spawn_interval)
	spawn_timer.wait_time = normal_interval
	spawn_timer.start()
