extends Node

class_name GameManager

## Game Manager for "The Last Eagle"
## Manages coordination between different game systems
## Handles world movement speed synchronization

# Reference to game systems
@export var obstacle_spawner_path: NodePath
@export var parallax_background_path: NodePath

var obstacle_spawner: ObstacleSpawner
var parallax_background: ParallaxBackgroundSystem

func _ready():
	# Get references to game systems
	obstacle_spawner = get_node(obstacle_spawner_path) if obstacle_spawner_path else null
	parallax_background = get_node(parallax_background_path) if parallax_background_path else null
	
	# Auto-find systems if paths not set
	if not obstacle_spawner:
		obstacle_spawner = find_child("ObstacleSpawner", true, false)
	if not parallax_background:
		parallax_background = find_child("ParallaxBackground", true, false)
	
	# Sync movement speeds
	sync_world_movement_speed()
	
	print("🎮 Game Manager initialized")
	print("   - Obstacle Spawner: ", "✓" if obstacle_spawner else "✗")
	print("   - Parallax Background: ", "✓" if parallax_background else "✗")

func sync_world_movement_speed():
	"""Synchronize world movement speed between systems"""
	if obstacle_spawner and parallax_background:
		var world_speed = obstacle_spawner.obstacle_movement_speed
		parallax_background.set_world_movement_speed(world_speed)
		print("🔄 Synced world movement speed: ", world_speed, " px/s")
		print("   - Gradient layer speed: ", parallax_background.get_gradient_scroll_speed(), " px/s")
		print("   - Mountain layer speed: ", parallax_background.get_mountain_scroll_speed(), " px/s")
		print("   - Middle layer speed: ", parallax_background.get_middle_scroll_speed(), " px/s")

func update_world_speed(new_speed: float):
	"""Update world movement speed for all systems"""
	if obstacle_spawner:
		obstacle_spawner.obstacle_movement_speed = new_speed
	if parallax_background:
		parallax_background.set_world_movement_speed(new_speed)
	print("🚀 Updated world speed to: ", new_speed, " px/s")

func toggle_parallax_middle_layer(enabled: bool):
	"""Toggle middle parallax layer for performance/artistic control"""
	if parallax_background:
		parallax_background.toggle_middle_layer(enabled)

func get_world_movement_speed() -> float:
	"""Get current world movement speed"""
	return obstacle_spawner.obstacle_movement_speed if obstacle_spawner else 300.0
