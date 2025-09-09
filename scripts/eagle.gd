class_name Eagle
extends CharacterBody2D

#@onready var animated_sprite = $Animation
#@onready var animated_sprite = $AnimatedSprite2D
@onready var screech_audio = $Screech
@onready var flap_audio = $FlapSound

@export var animated_sprite: AnimatedSprite2D

@export var balance_provider_path: NodePath
var balance_provider: BalanceProvider

# Import movement state enum from base controller
const MovementState = BaseMovementController.MovementState

# Game mechanics variables
@export var max_energy: float = 100.0
@export var energy_loss_per_second: float = 1.0  # Base energy loss over time
@export var energy_loss_per_flap: float = 3.0  # Energy lost per flap in flappy mode
@export var disable_passive_energy_loss: bool = false  # For flappy bird mode

# Energy capacity system variables (replaces morale system)
@export var energy_loss_per_nest_miss: float = 15.0  # Energy capacity lost when nest goes off screen
@export var energy_gain_per_nest_fed: float = 20.0  # Energy capacity gained when nest is fed
@export var initial_max_energy: float = 100.0  # Starting max energy capacity

# Hit system variables
@export var hit_energy_loss: float = 20.0  # Energy lost when hitting an obstacle
@export var hit_immunity_duration: float = 2.0  # Seconds of immunity after being hit
@export var hit_blink_duration: float = 3.0  # Seconds of blinking effect (can be longer than immunity)
@export var hit_blink_interval: float = 0.1  # How fast the blinking occurs

# Components
var movement_controller: BaseMovementController
var animation_controller: EagleAnimationController

# Energy and fish tracking
var current_energy: float = 100.0
var carried_fish: Fish = null  # Reference to the carried fish object

# Hit system state tracking
var is_immune: bool = false  # Whether eagle is immune to hits
var immunity_timer: float = 0.0  # Time remaining for immunity
var is_blinking: bool = false  # Whether eagle is currently blinking
var blink_timer: float = 0.0  # Time remaining for blinking effect
var blink_visible: bool = true  # Current visibility state during blinking
var blink_interval_timer: float = 0.0  # Timer for blink intervals
# Hit state is now managed by movement controller
var hit_state_timer: float = 0.0  # Timer to force exit from hit state if animation doesn't finish
var max_hit_state_duration: float = 1.0  # Maximum time allowed in hit state

# Signals - movement_state_changed is now handled by movement controller
signal screech_requested()
signal fish_caught_changed(has_fish: bool)  # Signal when fish carrying state changes
signal energy_capacity_changed(new_max_energy: float)  # Signal when energy capacity changes
signal eagle_died()  # Signal when eagle dies from energy depletion
signal eagle_hit()  # Signal when eagle gets hit by an obstacle

func _ready():
	print("Eagle ready! Node name: ", name)
	print("animated_sprite reference: ", animated_sprite)
	
	# Resolve balance provider and apply energy config
	if balance_provider_path != NodePath(""):
		balance_provider = get_node_or_null(balance_provider_path)
	if not balance_provider:
		balance_provider = get_tree().current_scene.find_child("BalanceProvider", true, false)
	if balance_provider and balance_provider.energy_config:
		var cfg := balance_provider.energy_config
		initial_max_energy = cfg.initial_max_energy
		max_energy = initial_max_energy
		energy_loss_per_second = cfg.energy_loss_per_second
		energy_loss_per_flap = cfg.energy_loss_per_flap
		energy_gain_per_nest_fed = cfg.energy_gain_per_nest_fed
		energy_loss_per_nest_miss = cfg.energy_loss_per_nest_miss
	else:
		# Fallback to current values if config not found
		initial_max_energy = max_energy  # Store initial max energy
	
	# Add eagle to group so enemies can find it
	add_to_group("eagle")
	
	# Initialize movement controller (using default for now)
	movement_controller = DefaultMovementController.new(self)
	add_child(movement_controller)
	print("Movement controller created and added as child")
	
	# Initialize animation controller
	animation_controller = EagleAnimationController.new(animated_sprite)
	add_child(animation_controller)
	print("Animation controller created and added as child")
	
	# Connect signals
	movement_controller.movement_state_changed.connect(animation_controller.handle_movement_state_change)
	screech_requested.connect(animation_controller.handle_screech_request)
	fish_caught_changed.connect(animation_controller.handle_fish_carrying_change)
	animation_controller.flap_animation_started.connect(play_flap_sound)
	print("Signals connected to animation controller")

	enable_flappy_mode()  # Switch to flappy bird controller


func _physics_process(delta):
	# 1. Handle special input actions
	handle_special_inputs()
	
	# 2. Handle fish actions
	handle_fish_actions()
	
	# 3. Update energy
	update_energy(delta)
	
	# 4. Update hit system (immunity and blinking)
	update_hit_system(delta)
	
	# 5. Movement is now handled by movement_controller in its _physics_process
	
	# 6. Apply movement (movement controller sets velocity, we apply it)
	move_and_slide()
	

func _unhandled_input(event):
	"""Handle debug input for testing"""
	if event is InputEventKey and event.pressed:
		# DEBUG: M key to decrease energy capacity (for testing diagonal pattern)
		if event.keycode == KEY_M:
			print("DEBUG: Manual energy capacity decrease triggered!")
			reduce_energy_capacity(15.0)
			get_viewport().set_input_as_handled()

# Fish management methods
func catch_fish(fish: Fish) -> bool:
	"""Called when the eagle catches a fish. Returns true if successful."""
	if carried_fish == null:  # Only catch if not already carrying
		carried_fish = fish
		print("Eagle caught a fish!")
		fish_caught_changed.emit(true)
		return true
	else:
		print("Eagle already carrying a fish - cannot catch another!")
		return false

func eat_fish():
	"""Called when the eagle eats a caught fish to restore energy"""
	if carried_fish != null:
		print("Eagle ate a fish!")
		# Use the fish's energy value instead of fixed amount
		var energy_gained = carried_fish.energy_value

		# Respect current max energy capacity limits (morale lock)
		current_energy = min(current_energy + energy_gained, max_energy)
		print("Energy gained from fish: ", energy_gained, " (Total energy: ", current_energy, "/", max_energy, ")")
		carried_fish.queue_free()  # Remove the fish from scene
		carried_fish = null
		fish_caught_changed.emit(false)
		return true
	return false

func drop_fish():
	"""Called when the eagle drops a fish to feed chicks"""
	if carried_fish != null:
		print("Eagle dropped a fish!")
		carried_fish.release_fish()  # Release the fish back to the world
		carried_fish = null
		fish_caught_changed.emit(false)
		return true
	return false

func has_fish() -> bool:
	"""Returns true if eagle is carrying a fish"""
	return carried_fish != null

# Energy capacity management methods
func reduce_energy_capacity(amount: float):
	"""Called when the eagle loses energy capacity (e.g., nest goes off screen)"""
	var old_max_energy = max_energy
	max_energy = max(max_energy - amount, 0.0)  # Can't go below 0
	
	if old_max_energy != max_energy:
		print("Eagle lost energy capacity: ", amount, " (Current max: ", max_energy, ")")
		
		# When max energy decreases, clamp current energy if needed
		if current_energy > max_energy:
			current_energy = max_energy
			print("Energy clamped to new capacity: ", current_energy, "/", max_energy)
		
		energy_capacity_changed.emit(max_energy)

func restore_energy_capacity(amount: float):
	"""Called when the eagle gains energy capacity (e.g., feeds a nest)"""
	var old_max_energy = max_energy
	max_energy = min(max_energy + amount, initial_max_energy)  # Can't exceed initial capacity
	
	if old_max_energy != max_energy:
		print("Eagle gained energy capacity: ", amount, " (Current max: ", max_energy, ")")
		
		# When max energy increases, current energy stays the same (don't auto-fill)
		print("Energy capacity increased to: ", max_energy, " (Current energy: ", current_energy, ")")
		
		energy_capacity_changed.emit(max_energy)

func get_energy_capacity_percentage() -> float:
	"""Returns energy capacity as a percentage (0.0 to 1.0) relative to initial capacity"""
	return max_energy / initial_max_energy

# Nest interaction methods
func on_nest_fed(points: int = 0):
	"""Called when a nest is successfully fed with a fish"""
	# Use the points from nest if provided, otherwise use eagle's default value
	var energy_to_gain: float = float(points) if points > 0 else energy_gain_per_nest_fed
	restore_energy_capacity(energy_to_gain)
	print("Nest fed! Eagle gained ", energy_to_gain, " energy capacity.")

func on_nest_missed(points: int = 0):
	"""Called when a nest goes off screen without being fed"""
	# Use the points from nest if provided, otherwise use eagle's default value
	var energy_to_lose: float = float(points) if points > 0 else energy_loss_per_nest_miss
	reduce_energy_capacity(energy_to_lose)
	print("Nest missed! Eagle lost ", energy_to_lose, " energy capacity.")

# Hit system methods
func hit_by_obstacle():
	"""Called when eagle collides with an obstacle"""
	print("hit_by_obstacle() called! is_immune:", is_immune)
	# Only take damage if not immune
	if not is_immune:
		print("Eagle hit by obstacle! Processing hit...")
		
		# Lose energy
		current_energy -= hit_energy_loss
		current_energy = max(current_energy, 0.0)
		print("Lost ", hit_energy_loss, " energy. Current energy: ", current_energy)
		
		# Drop fish if carrying one (as per GDD requirement)
		if has_fish():
			print("Eagle hit while carrying fish - dropping fish!")
			drop_fish()
		
		# Tell movement controller to handle hit state
		movement_controller.handle_hit_state()
		print("Movement controller set to HIT state")
		
		# Start immunity and blinking
		is_immune = true
		immunity_timer = hit_immunity_duration
		is_blinking = true
		blink_timer = hit_blink_duration
		blink_visible = true
		blink_interval_timer = 0.0
		hit_state_timer = 0.0  # Reset hit state timer
		
		# Emit hit signal
		eagle_hit.emit()
		
		# Check for death
		if current_energy <= 0.0:
			die()

func hit_by_enemy(enemy_body):
	"""Called when eagle is hit by an enemy bird"""
	# Prevent multiple hits while immune
	if is_immune:
		print("hit_by_enemy() called but eagle is immune!")
		return
	
	print("=== Eagle Hit by Enemy Processing ===")
	print("Eagle hit by enemy! Processing hit...")
	
	# Reduce energy
	current_energy -= hit_energy_loss
	current_energy = max(0, current_energy)  # Don't go below 0
	print("Lost ", hit_energy_loss, " energy. Current energy: ", current_energy)
	
	# Drop fish if carrying any
	if carried_fish != null:
		print("Eagle hit while carrying fish - dropping fish!")
		drop_fish()
	
	# Tell movement controller to handle hit state
	movement_controller.handle_hit_state()
	print("Movement controller set to HIT state")
	
	# Set immunity and blinking
	is_immune = true
	immunity_timer = hit_immunity_duration
	is_blinking = true
	blink_timer = hit_blink_duration
	blink_visible = true  # Start visible
	blink_interval_timer = 0.0
	hit_state_timer = 0.0  # Reset hit state timer
	
	# Tell the enemy bird it has hit the eagle
	if enemy_body.has_method("on_hit_eagle"):
		enemy_body.on_hit_eagle()
	
	# Emit hit signal
	eagle_hit.emit()
	
	# Check for death
	if current_energy <= 0.0:
		die()
	
	print("Hit by enemy processing complete!")
	print("=== End Eagle Hit by Enemy Processing ===")

func update_hit_system(delta):
	"""Update immunity and blinking timers"""
	# Update hit state timeout (safety mechanism)
	if movement_controller.get_movement_state() == MovementState.HIT:
		hit_state_timer += delta
		if hit_state_timer >= max_hit_state_duration:
			print("Hit state timeout reached - forcing exit from hit state")
			end_hit_state()
	
	# Update immunity timer
	if is_immune:
		immunity_timer -= delta
		if immunity_timer <= 0.0:
			is_immune = false
			print("Eagle immunity ended")
	
	# Update blinking effect
	if is_blinking:
		blink_timer -= delta
		blink_interval_timer += delta
		
		# Toggle visibility based on blink interval
		if blink_interval_timer >= hit_blink_interval:
			blink_visible = !blink_visible
			animated_sprite.visible = blink_visible
			blink_interval_timer = 0.0
		
		# End blinking when timer expires
		if blink_timer <= 0.0:
			is_blinking = false
			animated_sprite.visible = true  # Make sure eagle is visible
			blink_visible = true
			print("Eagle blinking ended")

func is_eagle_immune() -> bool:
	"""Returns true if eagle is currently immune to hits"""
	return is_immune

func end_hit_state():
	"""Called by animation controller when hit animation finishes"""
	if movement_controller.get_movement_state() == MovementState.HIT:
		print("Ending hit state, restoring movement controller")
		movement_controller.restore_from_hit_state()
		hit_state_timer = 0.0  # Reset hit state timer
		print("Eagle control restored! Current state: ", MovementState.keys()[movement_controller.get_movement_state()])

func _on_hit_detection_area_body_entered(body):
	"""Called when the HitDetectionArea overlaps with a body (obstacle or enemy)"""
	var current_movement_state = movement_controller.get_movement_state()
	var is_obstacle = body.is_in_group("obstacles")
	var is_enemy = body.is_in_group("enemies")
	
	print("Hit detection area triggered by: ", body.name, " | Is obstacle: ", is_obstacle, " | Is enemy: ", is_enemy, " | Is immune: ", is_immune, " | Current state: ", MovementState.keys()[current_movement_state])
	
	# Only process hits if not immune, not already in hit state, and the body is an obstacle or enemy
	if not is_immune and current_movement_state != MovementState.HIT and (is_obstacle or is_enemy):
		if is_obstacle:
			print("Eagle hit confirmed! Processing hit with obstacle: ", body.name)
			hit_by_obstacle()
		elif is_enemy:
			print("Eagle hit confirmed! Processing hit with enemy: ", body.name)
			hit_by_enemy(body)
	elif is_immune:
		print("Eagle is immune - hit ignored")
	elif current_movement_state == MovementState.HIT:
		print("Eagle already in hit state - hit ignored")
	else:
		print("Body is not an obstacle or enemy - hit ignored")

func handle_fish_actions():
	"""Handle input for eating or dropping fish"""
	if carried_fish != null:
		if Input.is_action_just_pressed("eat_fish"):
			eat_fish()
		elif Input.is_action_just_pressed("drop_fish"):
			drop_fish()

func update_energy(delta):
	"""Update eagle's energy over time"""
	# Only lose energy passively if not in flappy mode
	if not disable_passive_energy_loss:
		# Simple fixed energy loss over time
		current_energy -= energy_loss_per_second * delta
		current_energy = max(current_energy, 0.0)
	
	# Check for death condition
	if current_energy <= 0.0:
		die()

func consume_flap_energy():
	"""Called by flappy movement controller when eagle flaps"""
	current_energy -= energy_loss_per_flap
	current_energy = max(current_energy, 0.0)
	print("Eagle flapped! Energy lost: ", energy_loss_per_flap, " (Current: ", current_energy, ")")

func play_flap_sound():
	"""Called when eagle flaps to play the flapping sound"""
	if flap_audio != null:
		flap_audio.play()
		print("Playing flap sound")

func die():
	"""Called when the eagle dies from energy depletion"""
	print("Eagle died! Energy depleted.")
	eagle_died.emit()
	# TODO: Handle death state - disable controls, play death animation, etc.

# ===== MOVEMENT CONTROLLER MANAGEMENT =====

func set_movement_controller(new_controller: BaseMovementController):
	"""Change the movement controller - useful for experimenting with different movement feels"""
	if movement_controller:
		remove_child(movement_controller)
		movement_controller.queue_free()
	
	movement_controller = new_controller
	add_child(movement_controller)
	
	# Reconnect animation controller signal
	movement_controller.movement_state_changed.connect(animation_controller.handle_movement_state_change)
	print("Movement controller changed to: ", movement_controller.get_script().resource_path)

func enable_flappy_mode():
	"""Switch to flappy bird movement controller"""
	disable_passive_energy_loss = true
	var flappy_controller = FlappyMovementController.new(self)
	set_movement_controller(flappy_controller)
	print("Switched to Flappy Bird movement controller!")

func enable_default_mode():
	"""Switch to default movement controller"""
	disable_passive_energy_loss = false
	var default_controller = DefaultMovementController.new(self)
	set_movement_controller(default_controller)
	print("Switched to Default movement controller!")

func get_movement_state() -> MovementState:
	"""Get current movement state from movement controller"""
	return movement_controller.get_movement_state() if movement_controller else MovementState.GLIDING

func handle_special_inputs():
	# Handle screech input (H button)
	if Input.is_action_just_pressed("screech"):
		# Play screech sound
		screech_audio.play()
		# Trigger screech animation
		screech_requested.emit()
	

	
