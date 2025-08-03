# Separate animation controller class
# This handles ALL animation decisions and timing

class_name EagleAnimationController
extends Node

# Animation states - separate from movement states
enum AnimationState {
	GLIDE,
	FLAP_CONTINUOUS,  # Looping flap for active input
	FLAP_FINISHING,   # Finishing current flap before returning to glide
	GLIDE_FLAP,       # Non-looping flap for idle sequences
	SCREECH,          # Screech animation
	FLAP_TALONS_OUT,  # Flapping while carrying fish (talons extended)
	HIT               # Hit animation when eagle collides with obstacle
}

# Animation constants
const GLIDE_FLAP_CYCLES_MIN = 1
const GLIDE_FLAP_CYCLES_MAX = 3
const GLIDE_FLAP_INTERVAL_MIN = 3.0
const GLIDE_FLAP_INTERVAL_MAX = 7.0

# Animation state
var animation_state: AnimationState = AnimationState.GLIDE
var animated_sprite: AnimatedSprite2D

# Fish carrying state
var is_carrying_fish: bool = false

# Glide flap system
var glide_flap_timer: float = 0.0
var glide_flap_interval: float = 5.0
var glide_flap_cycles_remaining: int = 0

# Screech system
var previous_state_before_screech: AnimationState = AnimationState.GLIDE

# Hit system
var previous_state_before_hit: AnimationState = AnimationState.GLIDE

func _init(sprite: AnimatedSprite2D):
	print("Animation controller _init called with sprite: ", sprite)
	animated_sprite = sprite
	if animated_sprite == null:
		print("ERROR: animated_sprite is null!")
	else:
		print("animated_sprite set successfully")
		print("Available animations: ", animated_sprite.sprite_frames.get_animation_names())
	animated_sprite.animation_finished.connect(_on_animation_finished)
	print("animation_finished signal connected")
	reset_glide_flap_timer()

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	update_glide_flap_timer(delta)

func handle_fish_carrying_change(has_fish: bool):
	"""Handle when eagle starts or stops carrying fish"""
	is_carrying_fish = has_fish
	print("Eagle fish carrying state changed: ", has_fish)
	
	# Force animation update based on current movement state
	if has_fish:
		# Switch to talons out animation immediately
		if animation_state in [AnimationState.GLIDE, AnimationState.FLAP_CONTINUOUS, AnimationState.FLAP_FINISHING]:
			play_animation(AnimationState.FLAP_TALONS_OUT)
	else:
		# Return to normal animations
		# Determine appropriate animation based on current movement
		var eagle = get_parent() as Eagle
		if eagle:
			var current_state = eagle.get_movement_state()
			handle_movement_state_change(current_state, current_state)

func handle_movement_state_change(_old_state: BaseMovementController.MovementState, new_state: BaseMovementController.MovementState):
	print("Animation Controller received state change: ", BaseMovementController.MovementState.keys()[_old_state], " -> ", BaseMovementController.MovementState.keys()[new_state])
	
	# If carrying fish, prioritize talons out animation (except for SCREECH and HIT)
	if is_carrying_fish and animation_state != AnimationState.SCREECH and new_state != BaseMovementController.MovementState.HIT:
		print("Fish carrying logic: switching to talons out")
		if animation_state != AnimationState.FLAP_TALONS_OUT:
			play_animation(AnimationState.FLAP_TALONS_OUT)
		return
	
	# React to movement state changes using enum values
	match new_state:
		BaseMovementController.MovementState.GLIDING:
			# Check if we need to finish the current flap animation first
			if animation_state == AnimationState.FLAP_CONTINUOUS:
				# Don't interrupt mid-flap - let it finish first
				animation_state = AnimationState.FLAP_FINISHING
				print("Finishing current flap before returning to glide")
			elif animation_state != AnimationState.GLIDE_FLAP:
				# Safe to switch immediately (not mid-flap)
				play_animation(AnimationState.GLIDE)
		BaseMovementController.MovementState.LIFTING, BaseMovementController.MovementState.DIVING:
			# If we were finishing a flap, go back to continuous flapping
			if animation_state == AnimationState.FLAP_FINISHING:
				animation_state = AnimationState.FLAP_CONTINUOUS
				print("Resuming continuous flapping")
			else:
				play_animation(AnimationState.FLAP_CONTINUOUS)
		BaseMovementController.MovementState.HIT:
			# Save current state and play hit animation
			print("HIT case reached in animation controller!")
			if animation_state != AnimationState.HIT:
				previous_state_before_hit = animation_state
				print("Saved previous animation state: ", animation_state)
			print("About to call play_animation(AnimationState.HIT)")
			play_animation(AnimationState.HIT)
			print("Called play_animation(AnimationState.HIT) - hit animation should be playing")

func handle_screech_request():
	# Save current state to return to after screech
	if animation_state != AnimationState.SCREECH:
		previous_state_before_screech = animation_state
	
	# Play screech animation
	play_animation(AnimationState.SCREECH)
	print("Playing screech animation")

func update_glide_flap_timer(delta):
	# Only update timer during normal gliding (not during screech or carrying fish)
	if animation_state == AnimationState.GLIDE and not is_carrying_fish:
		glide_flap_timer += delta
		
		if glide_flap_timer >= glide_flap_interval:
			start_glide_flap_sequence()

func start_glide_flap_sequence():
	print("Starting glide flap sequence")
	glide_flap_cycles_remaining = randi_range(GLIDE_FLAP_CYCLES_MIN, GLIDE_FLAP_CYCLES_MAX)
	play_animation(AnimationState.GLIDE_FLAP)
	reset_glide_flap_timer()

func play_animation(new_animation_state: AnimationState):
	print("play_animation called with: ", new_animation_state)
	if new_animation_state == animation_state:
		print("Animation state unchanged, returning")
		return
		
	print("Changing animation state from ", animation_state, " to ", new_animation_state)
	animation_state = new_animation_state
	
	match animation_state:
		AnimationState.GLIDE:
			animated_sprite.play("glide")
		AnimationState.FLAP_CONTINUOUS:
			animated_sprite.play("flap")
		AnimationState.FLAP_FINISHING:
			# Don't change animation - let current flap finish
			pass
		AnimationState.GLIDE_FLAP:
			animated_sprite.play("flap")
		AnimationState.SCREECH:
			animated_sprite.play("screech")
		AnimationState.FLAP_TALONS_OUT:
			animated_sprite.play("talons_out")
		AnimationState.HIT:
			print("AnimationState.HIT case reached in play_animation!")
			print("animated_sprite reference: ", animated_sprite)
			print("Current animation: ", animated_sprite.animation)
			print("Available animations: ", animated_sprite.sprite_frames.get_animation_names())
			print("About to call animated_sprite.play('hit')")
			animated_sprite.play("hit")
			print("Called animated_sprite.play('hit')")
			print("Current animation after play: ", animated_sprite.animation)
			print("Animation should be playing now")

func reset_glide_flap_timer():
	glide_flap_timer = 0.0
	glide_flap_interval = randf_range(GLIDE_FLAP_INTERVAL_MIN, GLIDE_FLAP_INTERVAL_MAX)

func _on_animation_finished():
	# Handle animation sequence completion
	print("Animation finished: ", animation_state)
	match animation_state:
		AnimationState.FLAP_CONTINUOUS:
			# Keep looping the flap animation for continuous input
			animated_sprite.play("flap")
		AnimationState.FLAP_TALONS_OUT:
			# Keep looping the talons out animation while carrying fish
			if is_carrying_fish:
				animated_sprite.play("talons_out")
			else:
				# Fish was dropped/eaten during animation, return to normal
				var eagle = get_parent() as Eagle
				if eagle:
					var current_state = eagle.get_movement_state()
					handle_movement_state_change(current_state, current_state)
		AnimationState.FLAP_FINISHING:
			# Flap finished, now transition to glide or talons out
			print("Flap finished, transitioning to appropriate state")
			if is_carrying_fish:
				play_animation(AnimationState.FLAP_TALONS_OUT)
			else:
				play_animation(AnimationState.GLIDE)
		AnimationState.GLIDE_FLAP:
			glide_flap_cycles_remaining -= 1
			if glide_flap_cycles_remaining <= 0:
				# Return to appropriate state
				if is_carrying_fish:
					play_animation(AnimationState.FLAP_TALONS_OUT)
				else:
					play_animation(AnimationState.GLIDE)
			else:
				# Continue flapping
				if is_carrying_fish:
					animated_sprite.play("talons_out")
				else:
					animated_sprite.play("flap")
		AnimationState.SCREECH:
			# Screech finished, return to previous state
			print("Screech finished, returning to previous state")
			if is_carrying_fish:
				play_animation(AnimationState.FLAP_TALONS_OUT)
			else:
				play_animation(previous_state_before_screech)
		AnimationState.HIT:
			# Hit animation finished, tell eagle to end hit state and return to appropriate animation
			print("Hit animation finished")
			var eagle = get_parent() as Eagle
			if eagle:
				eagle.end_hit_state()  # This will trigger movement state change
			# The animation will be set by the subsequent movement state change
