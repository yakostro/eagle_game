extends Node

## GameStats - Global singleton for tracking game statistics across scenes
## AutoLoad singleton that persists data during scene transitions
## Acts as the "memory" of the game session

# Core game statistics
var fed_nests_count: int = 0
var session_start_time: float = 0.0
var best_record: int = 0  # Highest number of nests saved (persistent)

# Tweakable parameters for game balancing
@export var enable_debug_logging: bool = true
@export var save_file_path: String = "user://game_records.save"

# Signals for UI updates and other systems
signal stats_updated(fed_nests: int)
signal session_reset()
signal new_record_achieved(new_record: int)

func _ready():
	"""Initialize the GameStats singleton"""
	session_start_time = Time.get_unix_time_from_system()
	
	# Load saved records from disk
	_load_records()
	
	if enable_debug_logging:
		print("📊 GameStats singleton initialized")
		print("   Session started at: ", Time.get_datetime_string_from_system())
		print("   Current best record: ", best_record, " nests")

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

# === RECORD MANAGEMENT ===

func get_best_record() -> int:
	"""Get the current best record (highest saved nests)"""
	return best_record

func check_and_update_record() -> bool:
	"""Check if current session is a new record and update if so"""
	if fed_nests_count > best_record:
		var old_record = best_record
		best_record = fed_nests_count
		_save_records()
		
		if enable_debug_logging:
			print("🏆 NEW RECORD! Previous: ", old_record, " → New: ", best_record)
		
		new_record_achieved.emit(best_record)
		return true
	
	return false

func is_current_session_record() -> bool:
	"""Check if current session beats the best record"""
	return fed_nests_count > best_record

func _load_records():
	"""Load saved records from user data file"""
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var save_data = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(save_data)
			
			if parse_result == OK:
				var data = json.data
				if typeof(data) == TYPE_DICTIONARY and data.has("best_record"):
					best_record = data.best_record
					
					if enable_debug_logging:
						print("📁 Loaded record from save file: ", best_record)
				else:
					if enable_debug_logging:
						print("⚠️  Invalid save data format, using default record")
			else:
				if enable_debug_logging:
					print("⚠️  Failed to parse save file, using default record")
	else:
		if enable_debug_logging:
			print("📁 No save file found, starting with default record")

func _save_records():
	"""Save current records to user data file"""
	var save_data = {
		"best_record": best_record,
		"last_updated": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		
		if enable_debug_logging:
			print("💾 Records saved to file: ", save_file_path)
	else:
		if enable_debug_logging:
			print("❌ Failed to save records to file: ", save_file_path)

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
	print("Best Record: ", best_record)
	print("Is New Record: ", is_current_session_record())
	print("Session Duration: ", "%.1f" % get_session_duration(), " seconds")
	print("Session Start: ", Time.get_datetime_string_from_system(session_start_time))
	print("===========================")

func debug_set_fed_nests(count: int):
	"""Debug method to manually set fed nests count for testing"""
	if enable_debug_logging:
		print("🔧 DEBUG: Setting fed nests count to ", count)
	fed_nests_count = count
	stats_updated.emit(fed_nests_count)

func debug_set_record(record: int):
	"""Debug method to manually set the best record for testing"""
	if enable_debug_logging:
		print("🔧 DEBUG: Setting best record to ", record)
	best_record = record
	_save_records()

func debug_reset_records():
	"""Debug method to reset all saved records"""
	if enable_debug_logging:
		print("🔧 DEBUG: Resetting all records")
	best_record = 0
	_save_records()
