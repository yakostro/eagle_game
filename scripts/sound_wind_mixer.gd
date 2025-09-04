extends Node

# Audio players
@onready var base_wind: AudioStreamPlayer2D = $BaseWind
@onready var additional_wind: AudioStreamPlayer2D = $AdditionalWind

# Configuration variables
@export var base_wind_volume: float = -15.0
@export var additional_wind_volume: float = -18.0
@export var min_interval: float = 8.0    # Minimum time between additional wind plays
@export var max_interval: float = 20.0   # Maximum time between additional wind plays
@export var fade_duration: float = 1.5   # Fade in/out time for additional wind

# Scene start fade-in configuration
@export_group("Scene Start Settings")
@export var scene_start_fade_duration: float = 2.0  # Fade-in duration when scene starts
@export var enable_scene_start_fade: bool = true    # Enable/disable scene start fade-in

# Additional wind segment configuration  
@export var min_segment_duration: float = 5.0   # Minimum segment length
@export var max_segment_duration: float = 12.0   # Maximum segment length

# Internal variables
var additional_wind_timer: Timer
var fade_tween: Tween
var scene_start_tween: Tween
var additional_wind_audio_length: float = 0.0

func _ready():
	print("Wind mixer starting...")
	
	# Set up base wind (continuous loop)
	if base_wind:
		print("BaseWind node found")
		if base_wind.stream:
			print("BaseWind stream found: ", base_wind.stream)
			
			# Set loop for base wind (should be AudioStreamOggVorbis which supports loop)
			if base_wind.stream.has_method("set_loop"):
				base_wind.stream.set_loop(true)
				print("Set loop to true for base wind")
			
			# Start base wind with fade-in effect
			_start_base_wind_with_fade_in()
		else:
			print("ERROR: BaseWind has no stream assigned!")
	else:
		print("ERROR: BaseWind node not found!")
	
	# Set up additional wind
	if additional_wind:
		print("AdditionalWind node found")
		if additional_wind.stream:
			print("AdditionalWind stream found: ", additional_wind.stream)
			additional_wind.volume_db = additional_wind_volume
			# Don't set loop for additional wind - we control playback manually
			# Get the audio length for segment calculation
			additional_wind_audio_length = additional_wind.stream.get_length()
			print("Additional wind length: ", additional_wind_audio_length, " seconds")
		else:
			print("ERROR: AdditionalWind has no stream assigned!")
	else:
		print("ERROR: AdditionalWind node not found!")
	
	# Create timer for additional wind intervals
	additional_wind_timer = Timer.new()
	additional_wind_timer.wait_time = 3.0  # Start first additional wind in 3 seconds for testing
	additional_wind_timer.timeout.connect(_play_additional_wind_segment)
	additional_wind_timer.one_shot = true
	add_child(additional_wind_timer)
	additional_wind_timer.start()
	print("Additional wind timer started, first play in ", additional_wind_timer.wait_time, " seconds")
	
	print("Wind mixer setup complete")

func _start_base_wind_with_fade_in():
	"""Start the base wind with a smooth fade-in effect"""
	if not base_wind or not base_wind.stream:
		return
	
	if enable_scene_start_fade:
		print("Starting base wind with ", scene_start_fade_duration, "s fade-in...")
		
		# Start playing but at silent volume
		base_wind.volume_db = -80.0  # Very quiet to start
		base_wind.play()
		
		# Create fade-in tween
		scene_start_tween = create_tween()
		scene_start_tween.tween_property(base_wind, "volume_db", base_wind_volume, scene_start_fade_duration)
		scene_start_tween.tween_callback(_on_base_wind_fade_in_complete)
	else:
		# Start immediately at full volume
		print("Starting base wind immediately at full volume...")
		base_wind.volume_db = base_wind_volume
		base_wind.play()
		_on_base_wind_fade_in_complete()

func _on_base_wind_fade_in_complete():
	"""Called when the base wind fade-in is complete"""
	print("BaseWind fade-in complete. Final volume: ", base_wind.volume_db, "dB")

func _play_additional_wind_segment():
	"""Play a random segment of the additional wind sound"""
	print("=== Additional wind segment triggered ===")
	
	if not additional_wind or not additional_wind.stream:
		print("ERROR: Additional wind or stream not available")
		return
	
	# Calculate random segment
	var segment_duration = randf_range(min_segment_duration, max_segment_duration)
	var max_start_time = additional_wind_audio_length - segment_duration
	var start_time = 0.0
	
	if max_start_time <= 0:
		# Audio is shorter than segment, play the whole thing
		start_time = 0.0
		segment_duration = additional_wind_audio_length
		print("Playing whole audio file: ", segment_duration, " seconds")
	else:
		# Pick random start point
		start_time = randf_range(0.0, max_start_time)
		print("Playing segment from ", start_time, " to ", start_time + segment_duration, " seconds")
	
	# Set volume and start playing
	additional_wind.volume_db = -80.0  # Start silent for fade-in
	additional_wind.play()
	
	# Seek to position after starting playback
	if start_time > 0.0:
		additional_wind.seek(start_time)
		print("Seeked to position: ", start_time)
	
	print("Additional wind started playing at volume: ", additional_wind.volume_db)
	
	# Fade in
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(additional_wind, "volume_db", additional_wind_volume, fade_duration)
	
	# Schedule fade out and stop
	var play_time = segment_duration - (fade_duration * 2)
	if play_time > 0:
		fade_tween.tween_interval(play_time)  # Play time minus fade times
		fade_tween.tween_property(additional_wind, "volume_db", -80.0, fade_duration)
		fade_tween.tween_callback(additional_wind.stop)
		print("Scheduled fade out in ", play_time, " seconds")
	else:
		# If segment is too short, just play without fade out
		print("Segment too short for fade, playing for ", segment_duration, " seconds")
	
	# Schedule next additional wind play
	additional_wind_timer.wait_time = randf_range(min_interval, max_interval)
	additional_wind_timer.start()
	print("Next additional wind in ", additional_wind_timer.wait_time, " seconds")
	
	print("=== Additional wind setup complete ===")

func set_base_wind_volume(volume: float):
	"""Set the volume of the base wind"""
	base_wind_volume = volume
	if base_wind:
		# Only set immediately if not currently fading in
		if not scene_start_tween or not scene_start_tween.is_valid():
			base_wind.volume_db = volume
		else:
			print("Base wind volume change deferred - fade-in in progress")

func set_additional_wind_volume(volume: float):
	"""Set the volume of the additional wind"""
	additional_wind_volume = volume

func toggle_wind():
	"""Toggle both wind sounds on/off"""
	if base_wind:
		if base_wind.playing:
			base_wind.stop()
			additional_wind_timer.stop()
			if additional_wind:
				additional_wind.stop()
		else:
			base_wind.play()
			additional_wind_timer.start()

func set_wind_intensity(intensity: float):
	"""Set wind intensity (0.0 to 1.0) - affects both base and additional wind volume"""
	var base_vol = lerp(-25.0, -10.0, intensity)
	var additional_vol = lerp(-30.0, -15.0, intensity)
	
	set_base_wind_volume(base_vol)
	set_additional_wind_volume(additional_vol)

# Input for testing - DISABLED to prevent conflicts with game controls
# Use these methods directly for testing instead of keyboard input
#func _input(event):
#	if event.is_action_pressed("ui_accept"):  # Spacebar
#		toggle_wind()
#	elif event.is_action_pressed("ui_left"):   # Left arrow  
#		set_wind_intensity(0.3)
#	elif event.is_action_pressed("ui_right"):  # Right arrow
#		set_wind_intensity(1.0)
#	elif event.is_action_pressed("ui_up"):     # Up arrow
#		_play_additional_wind_segment()  # Manual trigger for testing
