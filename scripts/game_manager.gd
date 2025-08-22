extends Node

class_name GameManager

## Game Manager for "The Last Eagle"
## Manages coordination between different game systems
## Handles world movement speed synchronization and game state management

# Reference to game systems
@export var obstacle_spawner_path: NodePath
@export var parallax_background_path: NodePath

# Reference to gameplay entities for game state management
@export var eagle_path: NodePath
@export var nest_spawner_path: NodePath

# Tweakable parameters for game over system
@export var game_over_transition_delay: float = 1.0  # Delay before transitioning to game over scene
@export var enable_game_state_logging: bool = true

var obstacle_spawner: ObstacleSpawner
var parallax_background: ParallaxBackgroundSystem
var eagle: Eagle
var nest_spawner: NestSpawner

# Game state tracking
var is_game_over: bool = false

func _ready():
	# Get references to game systems
	obstacle_spawner = get_node(obstacle_spawner_path) if obstacle_spawner_path else null
	parallax_background = get_node(parallax_background_path) if parallax_background_path else null
	eagle = get_node(eagle_path) if eagle_path else null
	nest_spawner = get_node(nest_spawner_path) if nest_spawner_path else null
	
	# Auto-find systems if paths not set
	if not obstacle_spawner:
		obstacle_spawner = find_child("ObstacleSpawner", true, false)
	if not parallax_background:
		parallax_background = find_child("ParallaxBackground", true, false)
	if not eagle:
		eagle = find_child("Eagle", true, false)
	if not nest_spawner:
		nest_spawner = find_child("NestSpawner", true, false)
	
	# Sync movement speeds
	sync_world_movement_speed()
	
	# Connect game state signals
	_connect_game_state_signals()
	
	print("🎮 Game Manager initialized")
	print("   - Obstacle Spawner: ", "✓" if obstacle_spawner else "✗")
	print("   - Parallax Background: ", "✓" if parallax_background else "✗")
	print("   - Eagle: ", "✓" if eagle else "✗")
	print("   - Nest Spawner: ", "✓" if nest_spawner else "✗")

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

# === GAME STATE MANAGEMENT ===

func _connect_game_state_signals():
	"""Connect signals for tracking game state and statistics"""
	# Connect to nest spawner for tracking nest feeding events
	if nest_spawner:
		# The nest spawner emits nest_spawned which gives us access to individual nests
		nest_spawner.nest_spawned.connect(_on_nest_spawned)
		if enable_game_state_logging:
			print("🔗 Connected to nest spawner signals")
	
	# Connect to eagle for death events
	if eagle:
		eagle.eagle_died.connect(_on_eagle_died)
		if enable_game_state_logging:
			print("🔗 Connected to eagle death signal")

func _on_nest_spawned(nest: Node):
	"""Called when a new nest is spawned - connect to its feeding signal"""
	if not nest:
		return
	
	# Connect to this specific nest's feeding signal
	nest.nest_fed.connect(_on_nest_fed)
	
	if enable_game_state_logging:
		print("🏠 Connected to new nest feeding signal: ", nest.name)

func _on_nest_fed(_points: int = 0):
	"""Called when any nest is successfully fed with a fish"""
	if is_game_over:
		return  # Don't track stats after game over
	
	# Increment the fed nests count in our global statistics
	if GameStats:
		GameStats.increment_fed_nests()
		if enable_game_state_logging:
			print("📊 Nest fed! Total fed nests: ", GameStats.get_fed_nests_count())
	else:
		print("❌ Warning: GameStats singleton not available for nest tracking")

func _on_eagle_died():
	"""Called when the eagle dies - trigger game over sequence"""
	if is_game_over:
		return  # Prevent multiple game over triggers
	
	is_game_over = true
	
	if enable_game_state_logging:
		print("💀 Eagle died! Triggering game over sequence...")
		if GameStats:
			print("📊 Final Statistics:")
			print("   - Fed Nests: ", GameStats.get_fed_nests_count())
			print("   - Session Duration: ", "%.1f" % GameStats.get_session_duration(), " seconds")
	
	# Add a small delay for dramatic effect before transitioning
	if game_over_transition_delay > 0.0:
		await get_tree().create_timer(game_over_transition_delay).timeout
	
	# Trigger game over scene transition
	_trigger_game_over_scene()

func _trigger_game_over_scene():
	"""Transition to the game over scene"""
	if enable_game_state_logging:
		print("🎬 Transitioning to game over scene...")
	
	# Use SceneManager for smooth transition
	if SceneManager:
		SceneManager.change_scene("res://scenes/game_over_scene.tscn")
	else:
		# Fallback if SceneManager not available
		print("⚠️  SceneManager not available, using direct scene change")
		get_tree().change_scene_to_file("res://scenes/game_over_scene.tscn")

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_trigger_game_over():
	"""Debug method to manually trigger game over for testing"""
	print("🔧 DEBUG: Manually triggering game over")
	_on_eagle_died()

func debug_add_fed_nest():
	"""Debug method to manually add a fed nest for testing"""
	print("🔧 DEBUG: Manually adding fed nest")
	_on_nest_fed(0)  # Points parameter not used, just pass 0
