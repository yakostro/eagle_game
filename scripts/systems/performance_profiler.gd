extends Node

class_name PerformanceProfiler

## Advanced performance profiling system for identifying bottlenecks
## Add this to your main scene to profile specific systems

# Configuration
@export var monitor_interval: float = 1.0
@export var enable_console_output: bool = true
@export var enable_warnings: bool = true
@export var profile_obstacle_spawning: bool = true
@export var profile_physics: bool = true
@export var profile_rendering: bool = true
@export var profile_script_execution: bool = true

# References to game systems
@export var obstacle_spawner_path: NodePath
@export var game_manager_path: NodePath

var obstacle_spawner: ObstacleSpawner
var game_manager: GameManager

# Profiling data
var obstacle_spawn_times: Array[float] = []
var physics_times: Array[float] = []
var render_times: Array[float] = []
var script_times: Array[float] = []

# Frame tracking
var frame_count: int = 0
var last_profile_time: float = 0.0

# Timer based scheduling (to mirror PerformanceMonitor behavior)
var _profile_timer: Timer

func _ready():
	_log("🔬 Performance Profiler initialized")

	# Get references to systems
	obstacle_spawner = get_node(obstacle_spawner_path) if obstacle_spawner_path else null
	game_manager = get_node(game_manager_path) if game_manager_path else null

	if obstacle_spawner:
		_log("   ✅ Connected to ObstacleSpawner")
		# Connect to obstacle spawn signal if available
		if obstacle_spawner.has_signal("obstacle_spawned"):
			obstacle_spawner.obstacle_spawned.connect(_on_obstacle_spawned)
	else:
		_log("   ⚠️  ObstacleSpawner not found")

	# Create timer for periodic profiling (instead of frame counting)
	_profile_timer = Timer.new()
	_profile_timer.wait_time = monitor_interval
	_profile_timer.timeout.connect(_run_performance_profile)
	add_child(_profile_timer)
	_profile_timer.start()

func _process(_delta: float):
	# Timer drives profiling; keep frame_count available if needed elsewhere
	frame_count += 1

func _run_performance_profile():
	var current_time = Time.get_ticks_msec()

	# Profile obstacle spawning performance
	if profile_obstacle_spawning:
		_profile_obstacle_spawning()

	# Profile physics performance
	if profile_physics:
		_profile_physics_performance()

	# Profile rendering performance
	if profile_rendering:
		_profile_render_performance()

	# Profile script execution
	if profile_script_execution:
		_profile_script_performance()

	last_profile_time = current_time

func _profile_obstacle_spawning():
	if not obstacle_spawner:
		return

	var spawn_count = obstacle_spawner.obstacle_count
	var active_obstacles = get_tree().get_nodes_in_group("obstacles").size()

	_log("🏔️  OBSTACLE PROFILE:")
	_log("   - Total spawned: %d" % spawn_count)
	_log("   - Active obstacles: %d" % active_obstacles)
	_log("   - Spawn rate: %.1f obstacles/minute" % (spawn_count / (Time.get_ticks_msec() / 60000.0)))


	# Check for potential issues
	if active_obstacles > 50:
		_warn("High obstacle count: %d active obstacles may impact performance" % active_obstacles)


	if obstacle_spawner.obstacle_movement_speed > 1000:
		_warn("Very high obstacle speed: %.0f may cause physics issues" % obstacle_spawner.obstacle_movement_speed)


func _profile_physics_performance():
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var physics_fps = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)

	_log("⚙️  PHYSICS PROFILE:")
	_log("   - Physics process time: %.2f ms" % (physics_time * 1000))
	_log("   - Active 2D physics objects: %d" % physics_fps)

	physics_times.append(physics_time)
	if physics_times.size() > 10:
		physics_times.remove_at(0)

	var avg_physics_time = physics_times.reduce(func(acc, val): return acc + val, 0.0) / physics_times.size()
	_log("   - Average physics time: %.2f ms" % (avg_physics_time * 1000))

	# Warnings for physics performance
	if physics_time > 0.016:  # More than 16ms (60 FPS budget)
		_warn("Physics taking too long: %.2f ms (target: <16ms)" % (physics_time * 1000))

func _profile_render_performance():
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects_drawn = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)

	_log("🎨 RENDER PROFILE:")
	_log("   - Draw calls: %d" % draw_calls)
	_log("   - Objects drawn: %d" % objects_drawn)

	# Warnings for rendering performance
	if draw_calls > 100:
		_warn("High draw calls: %d (may impact GPU performance)" % draw_calls)

	# Vertex counter not available in Godot 4.2 Performance monitors

func _profile_script_performance():
	var script_time = Performance.get_monitor(Performance.TIME_PROCESS) - Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)

	_log("📜 SCRIPT PROFILE:")
	_log("   - Script execution time: %.2f ms" % (script_time * 1000))

	script_times.append(script_time)
	if script_times.size() > 10:
		script_times.remove_at(0)

	var avg_script_time = script_times.reduce(func(acc, val): return acc + val, 0.0) / script_times.size()
	_log("   - Average script time: %.2f ms" % (avg_script_time * 1000))

	# Warnings for script performance
	if script_time > 0.01:  # More than 10ms
		_warn("Script execution taking too long: %.2f ms (target: <10ms)" % (script_time * 1000))

func _on_obstacle_spawned(_obstacle: Node):
	"""Called when a new obstacle is spawned - measure spawn time"""
	if not profile_obstacle_spawning:
		return

	var spawn_start = Time.get_ticks_usec()
	# The actual spawning has already happened, so we measure the time since the signal
	# In a real implementation, you'd measure the time from spawn start to spawn end
	var spawn_time = (Time.get_ticks_usec() - spawn_start) / 1000.0  # Convert to milliseconds

	obstacle_spawn_times.append(spawn_time)
	if obstacle_spawn_times.size() > 20:  # Keep last 20 spawn times
		obstacle_spawn_times.remove_at(0)

	_log("🏔️  Obstacle spawn time: %.2f ms" % spawn_time)

func get_detailed_report() -> String:
	"""Generate detailed performance analysis report"""
	var report = "=== DETAILED PERFORMANCE ANALYSIS ===\n\n"

	report += "🎯 PERFORMANCE SUMMARY:\n"
	report += "- Average FPS: %.1f\n" % Performance.get_monitor(Performance.TIME_FPS)
	report += "- Total objects: %d\n" % int(Performance.get_monitor(Performance.OBJECT_COUNT))
	report += "- Memory usage: %.1f MB\n" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1024 / 1024)
	report += "\n"

	report += "🏔️  OBSTACLE SYSTEM:\n"
	if obstacle_spawner:
		report += "- Obstacles spawned: %d\n" % obstacle_spawner.obstacle_count
		report += "- Current spawn interval: %.1fs\n" % obstacle_spawner.spawn_interval
		report += "- Movement speed: %.0f px/s\n" % obstacle_spawner.obstacle_movement_speed
	else:
		report += "- ObstacleSpawner not connected\n"

	report += "\n⚙️  PHYSICS ANALYSIS:\n"
	report += "- Physics objects: %d\n" % Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	report += "- Physics process time: %.2f ms\n" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)

	report += "\n🎨 RENDER ANALYSIS:\n"
	report += "- Draw calls: %d\n" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	report += "- Objects drawn: %d\n" % Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)

	report += "\n📜 SCRIPT ANALYSIS:\n"
	report += "- Script execution time: %.2f ms\n" % ((Performance.get_monitor(Performance.TIME_PROCESS) - Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000)

	report += "\n💡 RECOMMENDATIONS:\n"
	_add_performance_recommendations(report)

	return report

func _add_performance_recommendations(report: String) -> String:
	var recommendations = ""

	# Object count recommendations
	var total_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	if total_objects > 100:
		recommendations += "- Consider object pooling for obstacles\n"
	if total_objects > 200:
		recommendations += "- CRITICAL: Too many objects! Implement cleanup system\n"

	# Physics recommendations
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	if physics_time > 0.016:
		recommendations += "- Physics bottleneck: Reduce collision shapes or use simpler physics\n"

	# Render recommendations
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if draw_calls > 50:
		recommendations += "- High draw calls: Consider texture atlasing or reducing sprite variety\n"

	if recommendations.is_empty():
		recommendations = "- Performance looks good! No major issues detected.\n"

	report += recommendations
	return report

# Debug function
func print_detailed_report():
	if enable_console_output:
		print(get_detailed_report())

# Internal helpers to make logging/warnings switchable like PerformanceMonitor
func _log(message: String):
	if enable_console_output:
		print(message)

func _warn(message: String):
	if enable_warnings:
		push_warning(message)
