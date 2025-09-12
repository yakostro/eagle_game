extends CPUParticles2D

# Wind particle controller
# This handles ONLY dynamic wind variations, not basic setup
# Configure basic particle properties through the Inspector!

# Wind behavior variables
var wind_intensity: float = 1.0
var wind_variation: float = 0.0
var wind_timer: float = 0.0

# Store initial values from inspector
var initial_velocity_min_base: float
var initial_velocity_max_base: float
var initial_direction: Vector2

func _ready():
	# This function runs automatically when the node enters the scene tree
	# Store the initial values from the inspector (don't override them!)
	initial_velocity_min_base = initial_velocity_min
	initial_velocity_max_base = initial_velocity_max
	initial_direction = direction
	

func _process(delta):
	# This function runs every frame
	# Add subtle wind variations over time (this is what the script controls)
	wind_timer += delta
	wind_variation = sin(wind_timer * 0.5) * 0.2 + cos(wind_timer * 0.3) * 0.1
	
	# DISABLED: Direction variation for consistent left movement
	# var varied_direction = initial_direction + Vector2(0, wind_variation)
	# direction = varied_direction.normalized()
	
	# Keep direction consistent (pure left movement)
	direction = initial_direction
	
	# Vary wind intensity slightly (modify inspector values, don't replace them)
	initial_velocity_min = initial_velocity_min_base + (wind_variation * 20)
	initial_velocity_max = initial_velocity_max_base + (wind_variation * 40)

# Public functions to control wind from other scripts
func set_wind_intensity(intensity: float):
	# Public function to control wind strength
	wind_intensity = clamp(intensity, 0.1, 2.0)
	initial_velocity_min = initial_velocity_min_base * wind_intensity
	initial_velocity_max = initial_velocity_max_base * wind_intensity
	amount = int(amount * wind_intensity)  # Modify current amount, don't set fixed value

func set_wind_direction(new_direction: Vector2):
	# Public function to control wind direction
	initial_direction = new_direction.normalized()
	direction = initial_direction

# Optional: Function to reset to inspector values
func reset_to_inspector_values():
	initial_velocity_min = initial_velocity_min_base
	initial_velocity_max = initial_velocity_max_base
	direction = initial_direction 
