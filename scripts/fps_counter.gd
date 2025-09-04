extends Label

class_name FPSCounter

## Simple FPS counter UI element
## Shows current FPS in the top right corner

@export var update_interval: float = 0.1  # Update frequency in seconds
@export var show_ms: bool = true  # Show frame time in milliseconds
@export var warning_threshold: int = 30  # FPS below this shows in red
@export var critical_threshold: int = 15  # FPS below this shows in dark red

var time_since_update: float = 0.0

func _ready():
	# Position in top right corner
	anchors_preset = PRESET_TOP_RIGHT
	offset_left = -100
	offset_top = 10
	offset_right = -10
	offset_bottom = 40

	# Styling
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_font_size_override("font_size", 18)
	z_index = 100  # Ensure it's on top

	print("🎯 FPS Counter initialized in top right corner")

func _process(delta: float):
	time_since_update += delta

	if time_since_update >= update_interval:
		time_since_update = 0.0
		_update_fps_display()

func _update_fps_display():
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000  # Convert to ms

	# Update color based on performance
	if fps < critical_threshold:
		add_theme_color_override("font_color", Color.DARK_RED)
	elif fps < warning_threshold:
		add_theme_color_override("font_color", Color.RED)
	else:
		add_theme_color_override("font_color", Color.WHITE)

	# Format display text
	if show_ms:
		text = "FPS: %.0f\n%.1f ms" % [fps, frame_time]
	else:
		text = "FPS: %.0f" % fps

# Debug function to toggle visibility
func toggle_visibility():
	visible = !visible
	print("🎯 FPS Counter visibility: ", "ON" if visible else "OFF")

# Input handling for debug toggle
func _input(event):
	if event is InputEventKey and event.pressed:
		# Toggle FPS counter with F12 key
		if event.keycode == KEY_F12:
			toggle_visibility()
			# Accept the event so it doesn't propagate
			get_viewport().set_input_as_handled()
