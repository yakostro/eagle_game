extends Node

## GameStats - Global singleton for tracking game statistics across scenes
## AutoLoad singleton that persists data during scene transitions
## Acts as the "memory" of the game session

# Core game statistics
var fed_nests_count: int = 0
var session_start_time: float = 0.0

# Tweakable parameters for game balancing
@export var enable_debug_logging: bool = true

# Signals for UI updates and other systems
signal stats_updated(fed_nests: int)
signal session_reset()

func _ready():
	"""Initialize the GameStats singleton"""
	session_start_time = Time.get_unix_time_from_system()
	
	if enable_debug_logging:
		print("📊 GameStats singleton initialized")
		print("   Session started at: ", Time.get_datetime_string_from_system())

# === NEST FEEDING STATISTICS ===

func increment_fed_nests():
	"""Called when a nest is successfully fed with a fish"""
	fed_nests_count += 1
	
	if enable_debug_logging:
		print("🏠 Fed nests count incremented to: ", fed_nests_count)
	
	# Notify other systems about the stats update
	stats_updated.emit(fed_nests_count)

func get_fed_nests_count() -> int:
	"""Get the current number of fed nests"""
	return fed_nests_count

# === SESSION MANAGEMENT ===

func reset_session():
	"""Reset all statistics for a new game session"""
	var old_fed_nests = fed_nests_count
	
	# Reset core statistics
	fed_nests_count = 0
	session_start_time = Time.get_unix_time_from_system()
	
	if enable_debug_logging:
		print("🔄 Game session reset!")
		print("   Previous fed nests: ", old_fed_nests)
		print("   New session started at: ", Time.get_datetime_string_from_system())
	
	# Notify systems about session reset
	session_reset.emit()

func get_session_duration() -> float:
	"""Get current session duration in seconds (for future use)"""
	var current_time = Time.get_unix_time_from_system()
	return current_time - session_start_time

# === FUTURE EXPANSION METHODS ===
# These methods are ready for when we add more statistics

func increment_fish_caught():
	"""Future: Track fish caught during session"""
	# TODO: Implement when fish catching statistics are needed
	pass

func increment_obstacles_survived():
	"""Future: Track obstacles successfully navigated"""
	# TODO: Implement when obstacle statistics are needed
	pass

# === DEBUG AND DEVELOPMENT HELPERS ===

func debug_print_stats():
	"""Print current statistics for debugging"""
	print("=== GameStats Debug Info ===")
	print("Fed Nests: ", fed_nests_count)
	print("Session Duration: ", "%.1f" % get_session_duration(), " seconds")
	print("Session Start: ", Time.get_datetime_string_from_system(session_start_time))
	print("===========================")

func debug_set_fed_nests(count: int):
	"""Debug method to manually set fed nests count for testing"""
	if enable_debug_logging:
		print("🔧 DEBUG: Setting fed nests count to ", count)
	fed_nests_count = count
	stats_updated.emit(fed_nests_count)
