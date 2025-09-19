# Separate animation controller class
# This handles ALL animation decisions and timing

class_name EagleAnimationController
extends Node

# Signals
signal flap_animation_started()  # Emitted when any flap animation starts

# Animation states - separate from movement states
enum AnimationState {
	GLIDE,
	FLAP_CONTINUOUS,  # Looping flap for active input
	FLAP_FINISHING,   # Finishing current flap before returning to glide
	SCREECH,          # Screech animation
	FLAP_TALONS_OUT,  # Flapping while carrying fish (talons extended)
	HIT,              # Hit animation when eagle collides with obstacle
	DYING             # Dying/falling animation when energy is depleted
}

# Animation constants
# (GLIDE_FLAP constants removed - no more automatic flapping during glide)

# Animation state
var animation_state: AnimationState = AnimationState.GLIDE
var animated_sprite: AnimatedSprite2D

# Fish carrying state
var is_carrying_fish: bool = false

# Glide flap system removed - no more automatic flapping during glide

# Screech system
var previous_state_before_screech: AnimationState = AnimationState.GLIDE

# Hit system
var previous_state_before_hit: AnimationState = AnimationState.GLIDE

func _init(sprite: AnimatedSprite2D):
	animated_sprite = sprite
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	else:
		print("❌ ERROR: Animation controller initialized with null sprite!")
	# No more glide flap timer initialization needed

func _ready():
	set_physics_process(true)

func _physics_process(_delta):
	# No more glide flap timer updates needed
	pass

func handle_fish_carrying_change(has_fish: bool):
	"""Handle when eagle starts or stops carrying fish"""
	is_carrying_fish = has_fish
	
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
	
	# If in dying state, don't override the dying animation
	if animation_state == AnimationState.DYING:
		return
	
	# If carrying fish, prioritize talons out animation (except for SCREECH and HIT)
	if is_carrying_fish and animation_state != AnimationState.SCREECH and new_state != BaseMovementController.MovementState.HIT:
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
			else:
				# Safe to switch immediately (not mid-flap)
				play_animation(AnimationState.GLIDE)
		BaseMovementController.MovementState.LIFTING, BaseMovementController.MovementState.DIVING:
			# If we were finishing a flap, go back to continuous flapping
			if animation_state == AnimationState.FLAP_FINISHING:
				animation_state = AnimationState.FLAP_CONTINUOUS
			else:
				play_animation(AnimationState.FLAP_CONTINUOUS)
		BaseMovementController.MovementState.HIT:
			# Save current state and play hit animation
			if animation_state != AnimationState.HIT:
				previous_state_before_hit = animation_state
			play_animation(AnimationState.HIT)

func handle_screech_request():
	# Save current state to return to after screech
	if animation_state != AnimationState.SCREECH:
		previous_state_before_screech = animation_state
		print("🦅 Screech requested. Saving previous state: ", AnimationState.keys()[previous_state_before_screech])
	
	# Play screech animation
	play_animation(AnimationState.SCREECH)

func handle_dying_state():
	"""Called when eagle enters dying state - plays dying animation"""
	play_animation(AnimationState.DYING)

# Glide flap functions removed - no more automatic flapping during glide

func play_animation(new_animation_state: AnimationState):
	if new_animation_state == animation_state:
		return
		
	animation_state = new_animation_state
	
	match animation_state:
		AnimationState.GLIDE:
			animated_sprite.play("glide")
		AnimationState.FLAP_CONTINUOUS:
			animated_sprite.play("flap")
			flap_animation_started.emit()  # Emit flap sound signal
		AnimationState.FLAP_FINISHING:
			# Don't change animation - let current flap finish
			pass
		# GLIDE_FLAP state removed - no more automatic flapping
		AnimationState.SCREECH:
			animated_sprite.play("screech")
		AnimationState.FLAP_TALONS_OUT:
			animated_sprite.play("talons_out")
			flap_animation_started.emit()  # Emit flap sound signal
		AnimationState.HIT:
			animated_sprite.play("hit")
		AnimationState.DYING:
			animated_sprite.play("dying")

# reset_glide_flap_timer function removed - no longer needed

func _on_animation_finished():
	# Handle animation sequence completion
	
	# If in dying state, let the animation stay on its final frame
	if animation_state == AnimationState.DYING:
		# Don't restart the animation - let it stay on the final frame
		return
	
	match animation_state:
		AnimationState.FLAP_CONTINUOUS:
			# Keep looping the flap animation for continuous input
			animated_sprite.play("flap")
			flap_animation_started.emit()  # Emit flap sound signal for each loop
		AnimationState.FLAP_TALONS_OUT:
			# Keep looping the talons out animation while carrying fish
			if is_carrying_fish:
				animated_sprite.play("talons_out")
				flap_animation_started.emit()  # Emit flap sound signal for each loop
			else:
				# Fish was dropped/eaten during animation, return to normal
				var eagle = get_parent() as Eagle
				if eagle:
					var current_state = eagle.get_movement_state()
					handle_movement_state_change(current_state, current_state)
		AnimationState.FLAP_FINISHING:
			# Flap finished, now transition to glide or talons out
			if is_carrying_fish:
				play_animation(AnimationState.FLAP_TALONS_OUT)
			else:
				play_animation(AnimationState.GLIDE)
		# GLIDE_FLAP case removed - no more automatic flapping sequences
		AnimationState.SCREECH:
			# Screech finished, return to previous state
			print("🦅 Screech animation finished. Returning to previous state: ", AnimationState.keys()[previous_state_before_screech])
			if is_carrying_fish:
				print("🦅 Eagle carrying fish, switching to talons out")
				play_animation(AnimationState.FLAP_TALONS_OUT)
			else:
				print("🦅 Returning to saved state: ", AnimationState.keys()[previous_state_before_screech])
				# Get current movement state to ensure we're synced
				var eagle = get_parent() as Eagle
				if eagle:
					var current_movement_state = eagle.get_movement_state()
					print("🦅 Current movement state: ", BaseMovementController.MovementState.keys()[current_movement_state])
					# Force sync with current movement state instead of saved state
					handle_movement_state_change(current_movement_state, current_movement_state)
				else:
					# Fallback to saved state if eagle not found
					play_animation(previous_state_before_screech)
		AnimationState.HIT:
			# Hit animation finished, tell eagle to end hit state and return to appropriate animation
			var eagle = get_parent() as Eagle
			if eagle:
				eagle.end_hit_state()  # This will trigger movement state change
			# The animation will be set by the subsequent movement state change
