extends Label

## Stage HUD Display
## Shows current stage information, game timer, and nest stats in the game UI

var game_timer: float = 0.0
var nest_spawner: NestSpawner
var last_second_displayed: int = -1

func _ready():
	# Connect to StageManager for stage updates
	_connect_to_stage_manager()
	
	# Find nest spawner for nest count info
	_find_nest_spawner()

func _process(delta):
	# Update game timer
	game_timer += delta
	
	# Update display only when seconds change (optimization)
	var current_second = int(game_timer)
	if current_second != last_second_displayed:
		last_second_displayed = current_second
		if StageManager and StageManager.current_stage_config:
			_update_stage_display(StageManager.current_stage, StageManager.current_stage_config)

func _find_nest_spawner():
	"""Find the nest spawner for nest count information"""
	nest_spawner = get_tree().current_scene.find_child("NestSpawner", true, false)
	if not nest_spawner:
		print("⚠️  StageHUD: Could not find NestSpawner")

func _connect_to_stage_manager():
	"""Connect to StageManager for automatic stage updates"""
	if StageManager:
		# Connect to stage change signal
		StageManager.stage_changed.connect(_on_stage_changed)
		
		# Update display with current stage immediately  
		if StageManager.current_stage_config:
			_update_stage_display(StageManager.current_stage, StageManager.current_stage_config)
		else:
			text = "Time: 00:00\nStage: Loading...\nNests: 0 fed / 0 spawned"
	else:
		text = "Time: 00:00\nStage: No StageManager\nNests: 0 fed / 0 spawned"
		print("⚠️  StageHUD: StageManager not available")

func _on_stage_changed(new_stage: int, config: StageConfiguration):
	"""Handle stage changes from StageManager"""
	# Force immediate update when stage changes
	last_second_displayed = -1  # Reset to force update
	_update_stage_display(new_stage, config)

func _update_stage_display(stage_number: int, config: StageConfiguration):
	"""Update the stage display text with stage, timer, and nest info"""
	var display_text = ""
	
	# Game timer (always show)
	var minutes = int(game_timer / 60)
	var seconds = int(game_timer) % 60
	display_text += "Time: %02d:%02d\n" % [minutes, seconds]
	
	# Stage information
	if config:
		# Show stage number and name
		display_text += "Stage %d: %s" % [stage_number, config.stage_name]
		
		# Add stage completion info
		if config.completion_type == StageConfiguration.CompletionType.TIMER:
			var remaining_time = config.completion_value - StageManager.stage_timer
			if remaining_time > 0:
				display_text += " (%.1fs)" % remaining_time
		elif config.completion_type == StageConfiguration.CompletionType.NESTS:
			var nests_needed = int(config.completion_value) - StageManager.stage_nest_count
			if nests_needed > 0:
				display_text += " (%d left)" % nests_needed
		
		display_text += "\n"
	else:
		display_text += "Stage %d: Unknown\n" % stage_number
	
	# Nest statistics
	var fed_nests = GameStats.get_fed_nests_count() if GameStats else 0
	var total_nests = nest_spawner.total_nests_spawned if nest_spawner else 0
	display_text += "Nests: %d fed / %d spawned" % [fed_nests, total_nests]
	
	text = display_text
