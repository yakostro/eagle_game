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

# Off-screen drain (overwritten from EnergyConfig in _ready())
@export var enable_offscreen_energy_loss: bool = true
@export var offscreen_energy_loss_per_second: float = 5.0
@export var offscreen_bounds_margin: float = 32.0
@export var camera_path: NodePath
var _camera: Camera2D

# Energy capacity system variables (replaces morale system)
@export var energy_loss_per_nest_miss: float = 15.0  # Energy capacity lost when nest goes off screen
@export var energy_gain_per_nest_fed: float = 20.0  # Energy capacity gained when nest is fed
@export var initial_max_energy: float = 100.0  # Starting max energy capacity

# Hit system variables
@export var hit_energy_loss: float = 20.0  # Energy lost when hitting an obstacle
@export var hit_immunity_duration: float = 2.0  # Seconds of immunity after being hit
@export var hit_blink_duration: float = 3.0  # Seconds of blinking effect (can be longer than immunity)
@export var hit_blink_interval: float = 0.1  # How fast the blinking occurs

# Death/Dying system variables
@export var death_boundary_margin: float = 100.0  # Pixels below screen to trigger game over
@export var min_death_fall_duration: float = 2.0  # Minimum fall time before game over
@export var death_animation_name: String = "dying"  # Animation to play when dying
@export var play_screech_on_zero_energy: bool = true  # Play screech once when entering dying
@export var play_screech_on_nest_missed: bool = true  # Play screech when missing a nest
@export var nest_missed_screech_volume_db: float = -10.0  # Volume for nest missed screech (separate from death screech)
@export var failed_flap_feedback_cooldown: float = 0.5  # Seconds between "No [energy icon]" messages

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

@export var instant_text_feedback_path: NodePath
var _instant_text_feedback: UIInstantTextFeedback
var is_dead: bool = false
var is_dying: bool = false  # Whether eagle is in dying state (can't flap, falling)
var death_fall_timer: float = 0.0  # Timer for minimum fall duration
var failed_flap_feedback_timer: float = 0.0  # Cooldown timer for "No [energy icon]" messages
var _offscreen_accum_timer: float = 0.0
var _offscreen_accum_amount: float = 0.0

func _ready():
	
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
		hit_energy_loss = cfg.hit_energy_loss
		enable_offscreen_energy_loss = cfg.enable_offscreen_energy_loss
		offscreen_energy_loss_per_second = cfg.offscreen_energy_loss_per_second
		offscreen_bounds_margin = cfg.offscreen_bounds_margin
	else:
		push_error("Eagle: Missing BalanceProvider.energy_config. Off-screen drain requires EnergyConfig.")
		return
	
	# Add eagle to group so enemies can find it
	add_to_group("eagle")
	
	# Initialize movement controller (using default for now)
	movement_controller = DefaultMovementController.new(self)
	add_child(movement_controller)

	# Initialize animation controller
	if animated_sprite:
		animation_controller = EagleAnimationController.new(animated_sprite)
		add_child(animation_controller)
	else:
		print("❌ ERROR: No animated sprite found for animation controller!")

	# Resolve camera reference
	if camera_path != NodePath(""):
		_camera = get_node_or_null(camera_path)
	if _camera == null:
		_camera = get_viewport().get_camera_2d()

	# Resolve instant text feedback node
	if instant_text_feedback_path != NodePath(""):
		_instant_text_feedback = get_node_or_null(instant_text_feedback_path)
	if _instant_text_feedback == null:
		_instant_text_feedback = get_tree().current_scene.find_child("UIInstantTextFeedback", true, false)
	
	# Connect signals
	movement_controller.movement_state_changed.connect(animation_controller.handle_movement_state_change)
	screech_requested.connect(animation_controller.handle_screech_request)
	fish_caught_changed.connect(animation_controller.handle_fish_carrying_change)
	animation_controller.flap_animation_started.connect(play_flap_sound)

	enable_flappy_mode()  # Switch to flappy bird controller


func _physics_process(delta):
	# Stop all runtime logic once dead
	if is_dead:
		return
	# 1. Handle special input actions
	handle_special_inputs()
	
	# 2. Handle fish actions
	handle_fish_actions()
	
	# 3. Update energy
	update_energy(delta)
	
	# 4. Update hit system (immunity and blinking)
	update_hit_system(delta)
	
	# 5. Update death/dying system timers
	update_dying_system(delta)
	
	# 6. Movement is now handled by movement_controller in its _physics_process
	
	# 7. Apply movement (movement controller sets velocity, we apply it)
	move_and_slide()
	

func _unhandled_input(event):
	"""Handle debug input for testing"""
	if event is InputEventKey and event.pressed:
		# DEBUG: M key to decrease energy capacity (for testing diagonal pattern)
		if event.keycode == KEY_M:
			reduce_energy_capacity(15.0)
			get_viewport().set_input_as_handled()
		# DEBUG: K key to test dying animation
		elif event.keycode == KEY_K:
			print("🔧 DEBUG: Manually triggering dying state")
			current_energy = 0.0
			die()
			get_viewport().set_input_as_handled()

# Fish management methods
func catch_fish(fish: Fish) -> bool:
	"""Called when the eagle catches a fish. Returns true if successful."""
	# Can't catch fish while dying
	if is_dying:
		return false
		
	if carried_fish == null:  # Only catch if not already carrying
		carried_fish = fish
		fish_caught_changed.emit(true)
		return true
	else:
		return false

func eat_fish():
	"""Called when the eagle eats a caught fish to restore energy"""
	# Can't eat fish while dying
	if is_dying:
		return
	if carried_fish != null:
		# Use the fish's energy value instead of fixed amount
		var energy_gained = carried_fish.energy_value

		# Respect current max energy capacity limits (morale lock)
		current_energy = min(current_energy + energy_gained, max_energy)
		carried_fish.queue_free()  # Remove the fish from scene
		carried_fish = null
		fish_caught_changed.emit(false)
		# Show instant gain feedback
		if _instant_text_feedback:
			_instant_text_feedback.show_feedback_at_gain(global_position, int(energy_gained))
		return true
	return false

func drop_fish():
	"""Called when the eagle drops a fish to feed chicks"""
	# Can't actively drop fish while dying (but should drop when entering dying state)
	if is_dying:
		return false
	if carried_fish != null:
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
		# When max energy decreases, clamp current energy if needed
		if current_energy > max_energy:
			current_energy = max_energy

		energy_capacity_changed.emit(max_energy)

func restore_energy_capacity(amount: float):
	"""Called when the eagle gains energy capacity (e.g., feeds a nest)"""
	var old_max_energy = max_energy
	max_energy = min(max_energy + amount, initial_max_energy)  # Can't exceed initial capacity

	print("🔧 DEBUG: restore_energy_capacity called - amount: ", amount, " old_max: ", old_max_energy, " new_max: ", max_energy)

	if old_max_energy != max_energy:
		# When max energy increases, current energy stays the same (don't auto-fill)
		print("🔧 DEBUG: Capacity changed, emitting signal with max_energy: ", max_energy)
		energy_capacity_changed.emit(max_energy)
	else:
		print("🔧 DEBUG: Capacity unchanged, no signal emitted")

func get_energy_capacity_percentage() -> float:
	"""Returns energy capacity as a percentage (0.0 to 1.0) relative to initial capacity"""
	return max_energy / initial_max_energy

# Nest interaction methods
func on_nest_fed(points: int = 0):
	"""Called when a nest is successfully fed with a fish"""
	# Can't gain energy while dying
	if is_dying:
		print("🔧 DEBUG: on_nest_fed called but eagle is dying - ignoring")
		return
	# Use the points from nest if provided, otherwise use eagle's default value
	var energy_to_gain: float = float(points) if points > 0 else energy_gain_per_nest_fed
	print("🔧 DEBUG: on_nest_fed called - points: ", points, " energy_to_gain: ", energy_to_gain)
	restore_energy_capacity(energy_to_gain)

func on_nest_missed(points: int = 0):
	"""Called when a nest goes off screen without being fed"""
	# Can't lose energy capacity while dying (already at 0 energy)
	if is_dying:
		return
	# Use the points from nest if provided, otherwise use eagle's default value
	var energy_to_lose: float = float(points) if points > 0 else energy_loss_per_nest_miss
	reduce_energy_capacity(energy_to_lose)
	
	# Play screech sound for missing nest
	play_nest_missed_screech()

# Hit system methods
func hit_by_obstacle():
	"""Called when eagle collides with an obstacle"""
	# Can't be hit while dying
	if is_dying:
		return
	# Only take damage if not immune
	if not is_immune:
		# Lose energy
		current_energy -= hit_energy_loss
		current_energy = max(current_energy, 0.0)

		# Drop fish if carrying one (as per GDD requirement)
		if has_fish():
			drop_fish()

		# Tell movement controller to handle hit state
		movement_controller.handle_hit_state()

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
		# Show instant text feedback
		if _instant_text_feedback:
			_instant_text_feedback.show_feedback_at(global_position, int(hit_energy_loss))

		# Check for death
		if current_energy <= 0.0:
			die()

func hit_by_enemy(enemy_body):
	"""Called when eagle is hit by an enemy bird"""
	# Can't be hit while dying
	if is_dying:
		return
	# Prevent multiple hits while immune
	if is_immune:
		return

	# Reduce energy
	current_energy -= hit_energy_loss
	current_energy = max(0, current_energy)  # Don't go below 0

	# Drop fish if carrying any
	if carried_fish != null:
		drop_fish()

	# Tell movement controller to handle hit state
	movement_controller.handle_hit_state()

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
	# Show instant text feedback
	if _instant_text_feedback:
		_instant_text_feedback.show_feedback_at(global_position, int(hit_energy_loss))

	# Check for death
	if current_energy <= 0.0:
		die()

func update_hit_system(delta):
	"""Update immunity and blinking timers"""
	# Update hit state timeout (safety mechanism)
	if movement_controller.get_movement_state() == MovementState.HIT:
		hit_state_timer += delta
		if hit_state_timer >= max_hit_state_duration:
			end_hit_state()

	# Update immunity timer
	if is_immune:
		immunity_timer -= delta
		if immunity_timer <= 0.0:
			is_immune = false

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

func update_dying_system(delta):
	"""Update dying system timers"""
	# Update feedback cooldown timer
	if failed_flap_feedback_timer > 0.0:
		failed_flap_feedback_timer -= delta
		failed_flap_feedback_timer = max(failed_flap_feedback_timer, 0.0)
	
	# Update death fall timer for minimum duration
	if is_dying:
		death_fall_timer += delta

func is_eagle_immune() -> bool:
	"""Returns true if eagle is currently immune to hits"""
	return is_immune

func end_hit_state():
	"""Called by animation controller when hit animation finishes"""
	if movement_controller.get_movement_state() == MovementState.HIT:
		movement_controller.restore_from_hit_state()
		hit_state_timer = 0.0  # Reset hit state timer

func _on_hit_detection_area_body_entered(body):
	"""Called when the HitDetectionArea overlaps with a body (obstacle or enemy)"""
	# No interactions while dying
	if is_dying:
		return
		
	var current_movement_state = movement_controller.get_movement_state()
	var is_obstacle = body.is_in_group("obstacles")
	var is_enemy = body.is_in_group("enemies")

	# Only process hits if not immune, not already in hit state, and the body is an obstacle or enemy
	if not is_immune and current_movement_state != MovementState.HIT and (is_obstacle or is_enemy):
		if is_obstacle:
			hit_by_obstacle()
		elif is_enemy:
			hit_by_enemy(body)

func handle_fish_actions():
	"""Handle input for eating or dropping fish"""
	# Can't perform fish actions while dying
	if is_dying:
		return
		
	if carried_fish != null:
		if Input.is_action_just_pressed("eat_fish"):
			eat_fish()
		elif Input.is_action_just_pressed("drop_fish"):
			drop_fish()

func update_energy(delta):
	"""Update eagle's energy over time"""
	if is_dead or is_dying:
		return
	# Only lose energy passively if not in flappy mode
	if not disable_passive_energy_loss:
		# Simple fixed energy loss over time
		current_energy -= energy_loss_per_second * delta
		current_energy = max(current_energy, 0.0)

	# Additional off-screen drain (always applies when enabled)
	if enable_offscreen_energy_loss and _is_off_screen():
		var loss = offscreen_energy_loss_per_second * delta
		current_energy -= loss
		current_energy = max(current_energy, 0.0)
		# Accumulate display amount and flush every second
		_offscreen_accum_timer += delta
		_offscreen_accum_amount += loss
		while _offscreen_accum_timer >= 1.0:
			# Calculate a 1-second chunk; ensure at least 1 if there was any loss
			var chunk := int(round(min(_offscreen_accum_amount, offscreen_energy_loss_per_second)))
			if chunk <= 0 and _offscreen_accum_amount > 0.0:
				chunk = 1
			if _instant_text_feedback and chunk > 0:
				var edge := 0 if global_position.y < _camera.global_position.y else 1
				_instant_text_feedback.show_feedback_at_edge(edge, chunk, global_position)
			# Decrease accumulators by 1 second worth
			_offscreen_accum_timer -= 1.0
			_offscreen_accum_amount = max(0.0, _offscreen_accum_amount - offscreen_energy_loss_per_second)
	else:
		# Reset accumulation when back on-screen so next offscreen starts fresh
		_offscreen_accum_timer = 0.0
		_offscreen_accum_amount = 0.0
	
	# Check for death condition
	if current_energy <= 0.0:
		die()

func _is_off_screen() -> bool:
	var cam := _camera if _camera != null else get_viewport().get_camera_2d()
	if cam == null:
		return false
	var center := cam.get_screen_center_position()
	var viewport_size := get_viewport().get_visible_rect().size
	var half_width := viewport_size.x * 0.5
	var half_height := viewport_size.y * 0.5
	var min_x := center.x - half_width - offscreen_bounds_margin
	var max_x := center.x + half_width + offscreen_bounds_margin
	var min_y := center.y - half_height - offscreen_bounds_margin
	var max_y := center.y + half_height + offscreen_bounds_margin
	var pos := global_position
	return pos.x < min_x or pos.x > max_x or pos.y < min_y or pos.y > max_y

func consume_flap_energy():
	"""Called by flappy movement controller when eagle flaps"""
	current_energy -= energy_loss_per_flap
	current_energy = max(current_energy, 0.0)

func play_flap_sound():
	"""Called when eagle flaps to play the flapping sound"""
	if flap_audio != null:
		flap_audio.play()

func play_nest_missed_screech():
	"""Play screech sound and animation when missing a nest with configurable volume"""
	if not play_screech_on_nest_missed or not screech_audio:
		return
	
	# Store original volume to restore later
	var original_volume = screech_audio.volume_db
	
	# Set the nest missed screech volume
	screech_audio.volume_db = nest_missed_screech_volume_db
	
	# Play the screech sound
	screech_audio.play()
	
	# Trigger screech animation
	screech_requested.emit()
	
	# Restore original volume after sound finishes (using a timer)
	var restore_timer = get_tree().create_timer(screech_audio.stream.get_length() if screech_audio.stream else 1.0)
	restore_timer.timeout.connect(func(): screech_audio.volume_db = original_volume)

func show_no_energy_feedback():
	"""Show 'No [energy icon]' feedback when trying to flap while dying"""
	if not is_dying:
		return  # Only show when dying
	
	# Check cooldown to prevent spam
	if failed_flap_feedback_timer > 0.0:
		return
	
	# Show the feedback using instant text system
	if _instant_text_feedback:
		# For now, use 0 as amount - we'll enhance the UI system to show "No Energy" text
		# The UI system will need to be modified to show custom text for 0 amount when dying
		_instant_text_feedback.show_feedback_at(global_position, 0)
		
	# Set cooldown timer
	failed_flap_feedback_timer = failed_flap_feedback_cooldown

func die():
	"""Called when the eagle dies from energy depletion"""
	if is_dead or is_dying:
		return
	is_dying = true
	death_fall_timer = 0.0  # Start timing the fall
	
	# Drop any carried fish when entering dying state
	if carried_fish != null:
		carried_fish.release_fish()  # Release the fish back to the world
		carried_fish = null
		fish_caught_changed.emit(false)
	
	# Trigger dying animation
	if animation_controller:
		animation_controller.handle_dying_state()
	else:
		print("❌ No animation controller found when trying to trigger dying animation")
	
	# Play screech sound once
	if play_screech_on_zero_energy and screech_audio:
		screech_audio.play()
	
	# Game over will be triggered by GameManager when eagle exits screen bottom
	# Don't emit eagle_died signal here anymore

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

func enable_flappy_mode():
	"""Switch to flappy bird movement controller"""
	disable_passive_energy_loss = true
	var flappy_controller = FlappyMovementController.new(self)
	set_movement_controller(flappy_controller)

func enable_default_mode():
	"""Switch to default movement controller"""
	disable_passive_energy_loss = false
	var default_controller = DefaultMovementController.new(self)
	set_movement_controller(default_controller)

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
	

	
