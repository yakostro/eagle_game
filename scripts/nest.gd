extends Node2D

class_name Nest

# Nest states
enum NestState {
	HUNGRY,
	FED
}

@export var balance_provider_path: NodePath
@export var eagle_reference_path: NodePath
@export var missed_detection_offset: float = 50.0  # Distance behind eagle when nest is considered "missed"

var balance_provider: BalanceProvider
var eagle_reference: Node2D

var current_state: NestState = NestState.HUNGRY
var animation_player: AnimatedSprite2D
var area_2d: Area2D
var fish_placeholder: Sprite2D
var sound_fed: AudioStreamPlayer2D
var has_emitted_missed: bool = false  # Track if missed signal was already emitted

# Signals
signal nest_fed(points: int)
signal nest_missed(points: int)

func _ready():
	# Resolve balance provider if present
	if balance_provider_path != NodePath(""):
		balance_provider = get_node_or_null(balance_provider_path)
	if not balance_provider:
		balance_provider = get_tree().current_scene.find_child("BalanceProvider", true, false)
	
	# Resolve eagle reference if present
	if eagle_reference_path != NodePath(""):
		eagle_reference = get_node_or_null(eagle_reference_path)
	if not eagle_reference:
		eagle_reference = get_tree().current_scene.find_child("Eagle", true, false)

	# Get references to child nodes
	animation_player = get_node("Animation")
	area_2d = get_node("Area2D")
	fish_placeholder = get_node("FishPlaceholder")
	sound_fed = get_node("SoundFed")
	
	# Set up collision detection for fish
	area_2d.collision_layer = 0  # Nest doesn't need to be on a collision layer
	area_2d.collision_mask = 1   # Detect bodies on layer 1 (fish should be on layer 1)
	
	# Connect collision signals  
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.area_entered.connect(_on_area_entered)  # Also detect area collisions
	
	# Set initial state
	set_state(NestState.HUNGRY)
	
	# Hide fish placeholder initially
	fish_placeholder.visible = false
	
	print("Nest initialized in HUNGRY state")

func _process(_delta):
	"""Handle missed signal when nest passes behind eagle + offset"""
	# Only emit missed signal if nest is still hungry and hasn't emitted before
	if current_state == NestState.HUNGRY and not has_emitted_missed and eagle_reference:
		# Check if nest has passed behind the eagle by the specified offset
		var eagle_x = eagle_reference.global_position.x
		var nest_x = global_position.x
		var missed_threshold = eagle_x - missed_detection_offset
		
		if nest_x < missed_threshold:
			print("Nest missed - passed behind eagle. Nest X: ", nest_x, " Eagle X: ", eagle_x, " Threshold: ", missed_threshold)
			nest_missed.emit(0)  # let eagle use EnergyConfig
			has_emitted_missed = true


func set_state(new_state: NestState):
	"""Change nest state and update animation"""
	current_state = new_state
	
	match current_state:
		NestState.HUNGRY:
			animation_player.play("hungry")
		NestState.FED:
			animation_player.play("fed")

func _on_body_entered(body):
	"""Handle collision with fish or other objects"""
	# Check if it's a fish using multiple methods for reliability
	if body is Fish or (body.has_method("get_class") and body.get_class() == "Fish"):
		if current_state == NestState.HUNGRY:
			print("Fish detected by nest: ", body.name)
			feed_nest(body)

func _on_area_entered(area):
	"""Handle area collision (fish CatchArea)"""
	var body = area.get_parent()
	if body and (body is Fish or (body.has_method("get_class") and body.get_class() == "Fish")):
		if current_state == NestState.HUNGRY:
			print("Fish CatchArea detected by nest: ", body.name)
			feed_nest(body)

func feed_nest(fish):
	"""Feed the nest with a fish"""
	if current_state != NestState.HUNGRY:
		return
	
	# Only accept fish that was dropped by the eagle
	if not fish.is_dropped:
		print("Fish rejected - not dropped by eagle")
		return
		
	print("Nest fed with fish!")
	
	# Change to fed state
	set_state(NestState.FED)
	
	# Play feeding sound with fade-out
	play_feeding_sound()
	
	# Show fish in placeholder (preserve position, scale, rotation as per GDD)
	fish_placeholder.visible = true
	var fish_sprite = fish.get_node("Sprite2D")
	if fish_sprite:
		fish_placeholder.texture = fish_sprite.texture
		
		# The fish sprite in the fish scene has scale Vector2(0.2, 0.2)
		# The FishPlaceholder in nest scene also has scale Vector2(0.2, 0.2)
		# We want to preserve the fish's scale RELATIVE to its sprite, not absolute
		# So we keep the placeholder's default scale and don't override it
		# fish_placeholder.scale remains Vector2(0.2, 0.2) as set in the nest scene
		
		fish_placeholder.rotation = fish.rotation  # Keep original fish rotation
		# Position is already set by the placeholder position in the nest scene
		print("Fish sprite displayed in nest with scale: ", fish_placeholder.scale, " rotation: ", fish_placeholder.rotation)
	else:
		print("Warning: Could not find Sprite2D in fish to display in nest")
	
	# Emit signal for eagle to increase energy capacity (use Eagle's EnergyConfig)
	nest_fed.emit(0)
	
	# Tell fish to handle its own cleanup
	fish.feed_to_nest()

func play_feeding_sound():
	"""Play the feeding sound"""
	if not sound_fed:
		print("Warning: SoundFed node not found")
		return
	
	sound_fed.play()
