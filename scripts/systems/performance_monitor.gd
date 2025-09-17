extends Node

class_name PerformanceMonitor

## Performance monitoring system for The Last Eagle
## Add this node to your game scene to monitor CPU, GPU, and memory usage

# Configuration
@export var monitor_interval: float = 1.0  # How often to update stats (seconds)
@export var show_fps: bool = true
@export var show_memory: bool = true
@export var show_gpu: bool = false  # GPU monitoring can be expensive
@export var show_object_count: bool = true
@export var enable_warnings: bool = true
@export var fps_warning_threshold: int = 30
@export var memory_warning_threshold_mb: int = 500
@export var enable_console_output: bool = true

# Performance tracking variables
var fps_timer: float = 0.0
var frame_count: int = 0
var min_fps: int = 999
var max_fps: int = 0
var avg_fps: float = 0.0
var fps_history: Array[float] = []

# Memory tracking
var memory_peak: float = 0.0
var memory_history: Array[float] = []

# Object tracking
var max_objects: int = 0
var object_history: Array[int] = []

# Performance monitoring timer
var monitor_timer: Timer

func _ready():
	if enable_console_output:
		print("📊 Performance Monitor initialized")
		print("   - Monitor interval: %.1fs" % monitor_interval)
		print("   - FPS warnings: %s" % ("ON" if enable_warnings else "OFF"))
		print("   - Memory warnings: %s" % ("ON" if enable_warnings else "OFF"))

	# Create and start monitoring timer
	monitor_timer = Timer.new()
	monitor_timer.wait_time = monitor_interval
	monitor_timer.timeout.connect(_on_monitor_timeout)
	add_child(monitor_timer)
	monitor_timer.start()

	# Initial stats
	if enable_console_output:
		_print_performance_stats()

func _process(delta: float):
	fps_timer += delta
	frame_count += 1

	# Update min/max FPS
	var current_fps = Performance.get_monitor(Performance.TIME_FPS)
	if current_fps < min_fps:
		min_fps = int(current_fps)
	if current_fps > max_fps:
		max_fps = int(current_fps)

func _on_monitor_timeout():
	if enable_console_output:
		_print_performance_stats()

func _print_performance_stats():
	var stats_text = "\n📊 PERFORMANCE STATS (%.1fs interval)" % monitor_interval

	if show_fps:
		var fps = Performance.get_monitor(Performance.TIME_FPS)
		fps_history.append(fps)

		# Keep only last 10 readings for average
		if fps_history.size() > 10:
			fps_history.remove_at(0)

		avg_fps = fps_history.reduce(func(acc, val): return acc + val, 0.0) / fps_history.size()

		stats_text += "\n   🎯 FPS: %.0f (avg: %.0f, min: %d, max: %d)" % [fps, avg_fps, min_fps, max_fps]

		# FPS warning
		if enable_warnings and fps < fps_warning_threshold:
			stats_text += " ⚠️ LOW FPS!"
			if enable_console_output:
				print(stats_text)
			push_warning("Low FPS detected: %.0f (below %d threshold)" % [fps, fps_warning_threshold])

	if show_memory:
		var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024 / 1024
		var total_memory = static_memory

		memory_history.append(total_memory)
		if memory_history.size() > 10:
			memory_history.remove_at(0)

		if total_memory > memory_peak:
			memory_peak = total_memory

		stats_text += "\n   🧠 Memory: %.1f MB (static: %.1f, peak: %.1f)" % [
			total_memory, static_memory, memory_peak
		]

		# Memory warning
		if enable_warnings and total_memory > memory_warning_threshold_mb:
			stats_text += " ⚠️ HIGH MEMORY!"
			push_warning("High memory usage: %.1f MB (above %d MB threshold)" % [total_memory, memory_warning_threshold_mb])

	if show_object_count:
		var total_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))

		object_history.append(total_objects)
		if object_history.size() > 10:
			object_history.remove_at(0)

		if total_objects > max_objects:
			max_objects = total_objects

		stats_text += "\n   📦 Objects: %d total (peak: %d)" % [
			total_objects, max_objects
		]

	if show_gpu:
		var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var objects_drawn = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		stats_text += "\n   🎨 GPU: %d draw calls, %d objects" % [draw_calls, objects_drawn]

	print(stats_text)

func get_performance_report() -> String:
	"""Generate a detailed performance report"""
	var report = "=== PERFORMANCE REPORT ===\n"
	report += "Session Duration: %.1f seconds\n" % (Time.get_ticks_msec() / 1000.0)
	report += "Average FPS: %.1f\n" % avg_fps
	report += "FPS Range: %d - %d\n" % [min_fps, max_fps]
	report += "Peak Memory: %.1f MB\n" % memory_peak
	report += "Peak Objects: %d\n" % max_objects

	if fps_history.size() > 0:
		var fps_1_percent_low = _get_percentile(fps_history, 0.01)
		report += "1%% Low FPS: %.1f (worst 1%% of frames)\n" % fps_1_percent_low

	return report

func _get_percentile(values: Array, percentile: float) -> float:
	"""Calculate percentile from array of values"""
	var sorted_values = values.duplicate()
	sorted_values.sort()
	var index = int(sorted_values.size() * percentile)
	if index >= sorted_values.size():
		index = sorted_values.size() - 1
	return sorted_values[index]

# Debug functions you can call from console
func reset_stats():
	"""Reset all performance statistics"""
	min_fps = 999
	max_fps = 0
	memory_peak = 0.0
	max_objects = 0
	fps_history.clear()
	memory_history.clear()
	object_history.clear()
	print("📊 Performance stats reset")

func force_gc():
	"""Force garbage collection (useful for memory testing)"""
	print("🗑️  Forcing garbage collection...")
	# Note: Godot doesn't have a direct force GC method, but we can suggest scene changes
	print("   💡 Tip: Change scenes or restart to trigger garbage collection")

# Keyboard shortcuts for debugging (call these in _input if needed)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_print_performance_stats()
			print("📊 Manual performance stats printed")
		elif event.keycode == KEY_F2:
			print(get_performance_report())
		elif event.keycode == KEY_F3:
			reset_stats()
