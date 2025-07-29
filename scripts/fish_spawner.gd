extends Node2D

class_name FishSpawner

@export var fish_scene: PackedScene  # Drag your Fish.tscn here
@export var spawn_interval: float = 3.0  # Seconds between spawns
@export var spawn_interval_variance: float = 1.0  # Random variation in timing
@export var min_spawn_interval: float = 1.0  # Minimum time between spawns
@export var eagle_reference: Eagle
@export var UI_fish_counter: Label

var spawn_timer: Timer
var screen_size: Vector2
#var eagle_reference: Eagle

func _ready():
	# Find the eagle (you can also drag and drop this in the inspector)
	eagle_reference = get_tree().current_scene.find_child("Eagle", true, false)
	if not eagle_reference:
		print("Warning: No eagle found! Make sure your eagle node is named 'Eagle'")
		return
	
	# Get screen size
	screen_size = get_viewport().get_visible_rect().size
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("Fish spawner initialized. Screen size: ", screen_size)

func _on_spawn_timer_timeout():
	spawn_fish()
	
	# Set random interval for next spawn
	var next_interval = spawn_interval + randf_range(-spawn_interval_variance, spawn_interval_variance)
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
	var fish = Fish.spawn_fish_at_bottom(get_tree(), fish_scene, eagle_reference, screen_size.x, screen_size.y)
	
	print("Spawned fish at position: ", fish.global_position)
	UI_fish_counter.text = '+1'

# Method to increase difficulty over time
func increase_difficulty():
	spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)
	print("Spawn interval reduced to: ", spawn_interval)

# Method to manually spawn fish (for testing)
func spawn_fish_now():
	spawn_fish()
