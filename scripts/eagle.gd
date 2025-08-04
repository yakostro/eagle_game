class_name Eagle
extends CharacterBody2D

#@onready var animated_sprite = $Animation
#@onready var animated_sprite = $AnimatedSprite2D
@onready var screech_audio = $Screech
@onready var state_label = $"../CanvasLayer/StateLabel"

@export var animated_sprite: AnimatedSprite2D

# Import movement state enum from base controller
const MovementState = BaseMovementController.MovementState

# Game mechanics variables (now using GameBalance singleton)
# Note: Individual @export vars removed - now using GameBalance singleton for all balance parameters
@export var hit_blink_duration: float = 3.0  # Seconds of blinking effect (can be longer than immunity)
@export var hit_blink_interval: float = 0.1  # How fast the blinking occurs

# Components
var movement_controller: BaseMovementController
var animation_controller: EagleAnimationController

# Energy and fish tracking
var current_energy: float
var current_morale: float
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
signal morale_changed(new_morale: float)  # Signal when morale changes
signal eagle_died()  # Signal when eagle dies from energy depletion
signal eagle_hit()  # Signal when eagle gets hit by an obstacle

func _ready():
	print("Eagle ready! Node name: ", name)
	print("animated_sprite reference: ", animated_sprite)
	
	# Initialize values from GameBalance singleton
	current_energy = GameBalance.eagle_starting_energy
	current_morale = GameBalance.starting_morale
	print("Eagle initialized with energy: ", current_energy, " and morale: ", current_morale)
	
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
	print("Signals connected to animation controller")

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
	
	# 7. Update UI
	update_UI()

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
		current_energy = min(current_energy + energy_gained, GameBalance.eagle_max_energy)
		print("Energy gained from fish: ", energy_gained, " (Total energy: ", current_energy, ")")
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

# Morale management methods
func lose_morale(amount: float):
	"""Called when the eagle loses morale (e.g., nest goes off screen)"""
	var old_morale = current_morale
	current_morale = max(current_morale - amount, 0.0)  # Can't go below 0
	if old_morale != current_morale:
		print("Eagle lost morale: ", amount, " (Current: ", current_morale, ")")
		morale_changed.emit(current_morale)

func gain_morale(amount: float):
	"""Called when the eagle gains morale (e.g., feeds a nest)"""
	var old_morale = current_morale
	current_morale = min(current_morale + amount, GameBalance.max_morale)
	if old_morale != current_morale:
		print("Eagle gained morale: ", amount, " (Current: ", current_morale, ")")
		morale_changed.emit(current_morale)

func get_current_morale() -> float:
	"""Returns current morale value"""
	return current_morale

func get_morale_percentage() -> float:
	"""Returns morale as a percentage (0.0 to 1.0)"""
	return current_morale / GameBalance.max_morale

# Nest interaction methods
func on_nest_fed(points: int = 0):
	"""Called when a nest is successfully fed with a fish"""
	# Use the points from nest if provided, otherwise use GameBalance default value
	var morale_to_gain: float = float(points) if points > 0 else GameBalance.morale_gain_fed_chick
	gain_morale(morale_to_gain)
	print("Nest fed! Eagle gained ", morale_to_gain, " morale points.")

func on_nest_missed(points: int = 0):
	"""Called when a nest goes off screen without being fed"""
	# Use the points from nest if provided, otherwise use GameBalance default value
	var morale_to_lose: float = float(points) if points > 0 else GameBalance.morale_loss_unfed_nest
	lose_morale(morale_to_lose)
	print("Nest missed! Eagle lost ", morale_to_lose, " morale points.")

# Hit system methods
func hit_by_obstacle():
	"""Called when eagle collides with an obstacle"""
	print("hit_by_obstacle() called! is_immune:", is_immune)
	# Only take damage if not immune
	if not is_immune:
		print("Eagle hit by obstacle! Processing hit...")
		
		# Lose energy
		current_energy -= GameBalance.obstacle_hit_energy_loss
		current_energy = max(current_energy, 0.0)
		print("Lost ", GameBalance.obstacle_hit_energy_loss, " energy. Current energy: ", current_energy)
		
		# Drop fish if carrying one (as per GDD requirement)
		if has_fish():
			print("Eagle hit while carrying fish - dropping fish!")
			drop_fish()
		
		# Tell movement controller to handle hit state
		movement_controller.handle_hit_state()
		print("Movement controller set to HIT state")
		
		# Start immunity and blinking
		is_immune = true
		immunity_timer = GameBalance.eagle_hit_immunity_duration
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
	current_energy -= GameBalance.enemy_bird_hit_energy_loss
	current_energy = max(0, current_energy)  # Don't go below 0
	print("Lost ", GameBalance.enemy_bird_hit_energy_loss, " energy. Current energy: ", current_energy)
	
	# Drop fish if carrying any
	if carried_fish != null:
		print("Eagle hit while carrying fish - dropping fish!")
		drop_fish()
	
	# Tell movement controller to handle hit state
	movement_controller.handle_hit_state()
	print("Movement controller set to HIT state")
	
	# Set immunity and blinking
	is_immune = true
	immunity_timer = GameBalance.eagle_hit_immunity_duration
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
	# Use GameBalance helper function to get energy loss rate based on current morale
	var energy_loss_rate = GameBalance.get_energy_loss_rate(current_morale)
	
	# Lose energy over time 
	var actual_energy_loss = energy_loss_rate * delta
	current_energy -= actual_energy_loss
	current_energy = max(current_energy, 0.0)
	
	# Check for death condition
	if current_energy <= 0.0:
		die()

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
	
	# DEBUG: Test hit system with T key
	if Input.is_action_just_pressed("ui_select"):  # Spacebar/Enter for testing
		print("DEBUG: Manual hit triggered!")
		hit_by_obstacle()

# Movement methods removed - now handled by movement_controller

func update_UI():
	var current_movement_state = movement_controller.get_movement_state()
	state_label.text = str(MovementState.keys()[current_movement_state])
	
	# Add hit state timer if in hit state
	if current_movement_state == MovementState.HIT:
		state_label.text += " (T:" + str("%.1f" % hit_state_timer) + ")"
	
	# Add fish carrying status
	if has_fish():
		state_label.text += " [FISH]"
	
	# Add immunity status
	if is_immune:
		state_label.text += " [IMMUNE]"
	
	# Add energy and morale to UI
	state_label.text += " Energy: " + str(int(current_energy))
	state_label.text += " | Morale: " + str(int(current_morale))
