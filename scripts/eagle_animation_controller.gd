# Separate animation controller class
# This handles ALL animation decisions and timing

class_name EagleAnimationController
extends Node

# Animation states - separate from movement states
enum AnimationState {
	GLIDE,
	FLAP_CONTINUOUS,  # Looping flap for active input
	FLAP_FINISHING,   # Finishing current flap before returning to glide
	GLIDE_FLAP        # Non-looping flap for idle sequences
}

# Animation constants
const GLIDE_FLAP_CYCLES_MIN = 1
const GLIDE_FLAP_CYCLES_MAX = 3
const GLIDE_FLAP_INTERVAL_MIN = 3.0
const GLIDE_FLAP_INTERVAL_MAX = 7.0

# Animation state
var animation_state: AnimationState = AnimationState.GLIDE
var animated_sprite: AnimatedSprite2D

# Glide flap system
var glide_flap_timer: float = 0.0
var glide_flap_interval: float = 5.0
var glide_flap_cycles_remaining: int = 0

func _init(sprite: AnimatedSprite2D):
	animated_sprite = sprite
	animated_sprite.animation_finished.connect(_on_animation_finished)
	reset_glide_flap_timer()

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	update_glide_flap_timer(delta)

func handle_movement_state_change(old_state_name: String, new_state_name: String):
	# React to movement state changes using string names
	match new_state_name:
		"GLIDING":
			# Check if we need to finish the current flap animation first
			if animation_state == AnimationState.FLAP_CONTINUOUS:
				# Don't interrupt mid-flap - let it finish first
				animation_state = AnimationState.FLAP_FINISHING
				print("Finishing current flap before returning to glide")
			elif animation_state != AnimationState.GLIDE_FLAP:
				# Safe to switch immediately (not mid-flap)
				play_animation(AnimationState.GLIDE)
		"FLAPPING", "DIVING":
			# If we were finishing a flap, go back to continuous flapping
			if animation_state == AnimationState.FLAP_FINISHING:
				animation_state = AnimationState.FLAP_CONTINUOUS
				print("Resuming continuous flapping")
			else:
				play_animation(AnimationState.FLAP_CONTINUOUS)

func update_glide_flap_timer(delta):
	# Only update timer during normal gliding
	if animation_state == AnimationState.GLIDE:
		glide_flap_timer += delta
		
		if glide_flap_timer >= glide_flap_interval:
			start_glide_flap_sequence()

func start_glide_flap_sequence():
	print("Starting glide flap sequence")
	glide_flap_cycles_remaining = randi_range(GLIDE_FLAP_CYCLES_MIN, GLIDE_FLAP_CYCLES_MAX)
	play_animation(AnimationState.GLIDE_FLAP)
	reset_glide_flap_timer()

func play_animation(new_animation_state: AnimationState):
	if new_animation_state == animation_state:
		return
		
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

func reset_glide_flap_timer():
	glide_flap_timer = 0.0
	glide_flap_interval = randf_range(GLIDE_FLAP_INTERVAL_MIN, GLIDE_FLAP_INTERVAL_MAX)

func _on_animation_finished():
	# Handle animation sequence completion
	match animation_state:
		AnimationState.FLAP_CONTINUOUS:
			# Keep looping the flap animation for continuous input
			animated_sprite.play("flap")
		AnimationState.FLAP_FINISHING:
			# Flap finished, now transition to glide
			print("Flap finished, transitioning to glide")
			play_animation(AnimationState.GLIDE)
		AnimationState.GLIDE_FLAP:
			glide_flap_cycles_remaining -= 1
			if glide_flap_cycles_remaining <= 0:
				# Return to normal glide
				play_animation(AnimationState.GLIDE)
			else:
				# Continue flapping
				animated_sprite.play("flap")
