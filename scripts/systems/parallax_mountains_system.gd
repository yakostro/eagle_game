extends Node2D

class_name ParallaxMountainsSystem

## Parallax Mountains System for "The Last Eagle"
## Creates atmospheric depth through two-layer parallax scrolling
## Syncs with existing world movement speed from obstacle system
## Custom implementation that doesn't rely on ParallaxBackground

# Configuration variables as per design document
@export_group("Layer Configuration")
@export var enable_middle_layer: bool = true
@export var mountains_scroll_speed: float = 0.1  # Multiplier for world speed (distant mountains)
@export var middle_scroll_speed: float = 0.4  # Multiplier for world speed (mid-distance)

@export_group("Layer Positioning")
@export var mountains_vertical_offset: float = 0.0  # Vertical offset for mountains layer (+ = down, - = up)
@export var middle_vertical_offset: float = 50.0  # Vertical offset for middle layer (+ = down, - = up)

@export_group("Mountains Textures")
@export var mountains_textures: Array[Texture2D] = []  # For mountains layer
@export var middle_textures: Array[Texture2D] = []  # For middle layer

@export_group("World Movement Integration")
@export var world_movement_speed: float = 300.0  # Should match obstacle_movement_speed

# Layer references (simple Node2D containers)
var mountains_layer: Node2D
var middle_layer: Node2D

# Sprite nodes for texture management
var mountains_sprites: Array[Sprite2D] = []
var middle_sprites: Array[Sprite2D] = []

# Screen dimensions
var screen_width: float
var screen_height: float

# Movement tracking
var mountains_scroll_position: float = 0.0
var middle_scroll_position: float = 0.0

func _ready():
	# Get screen dimensions
	screen_width = get_viewport().get_visible_rect().size.x
	screen_height = get_viewport().get_visible_rect().size.y
	
	# Set up parallax layers
	setup_mountains_layer()
	if enable_middle_layer:
		setup_middle_layer()
	
	print("🏔️  Parallax Mountains System initialized")
	print("   - Screen size: ", screen_width, "x", screen_height)
	print("   - World movement speed: ", world_movement_speed)
	print("   - Mountains scroll speed: ", world_movement_speed * mountains_scroll_speed)
	print("   - Mountains vertical offset: ", mountains_vertical_offset)
	print("   - Middle layer enabled: ", enable_middle_layer)
	if enable_middle_layer:
		print("   - Middle scroll speed: ", world_movement_speed * middle_scroll_speed)
		print("   - Middle vertical offset: ", middle_vertical_offset)

func setup_mountains_layer():
	"""Create and configure the mountains layer (distant mountains/sky)"""
	mountains_layer = Node2D.new()
	mountains_layer.name = "MountainsLayer"
	mountains_layer.z_index = -30  # Far behind everything
	add_child(mountains_layer)
	
	# Create sprites for mountains textures
	if not mountains_textures.is_empty():
		create_mountains_sprites()
	else:
		create_placeholder_mountains()

func setup_middle_layer():
	"""Create and configure the middle layer (mid-distance elements)"""
	middle_layer = Node2D.new()
	middle_layer.name = "MiddleLayer"
	middle_layer.z_index = -20  # Between background and foreground
	add_child(middle_layer)
	
	# Create sprites for middle textures
	if not middle_textures.is_empty():
		create_middle_sprites()
	else:
		create_placeholder_middle()

func create_mountains_sprites():
	"""Create sprite nodes for mountains textures"""
	if mountains_textures.is_empty():
		return
		
	# Use the first texture for the mountains layer
	var texture = mountains_textures[0]
	
	# Calculate scaling and dimensions
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()
	var scale_factor = screen_height / texture_height
	var scaled_width = texture_width * scale_factor
	
	# Create enough sprites to cover screen width + extra for scrolling
	var sprites_needed = int(ceil((screen_width * 3) / scaled_width)) + 1
	
	for i in range(sprites_needed):
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position.x = i * scaled_width
		sprite.position.y = screen_height / 2 + mountains_vertical_offset
		sprite.centered = true
		
		mountains_layer.add_child(sprite)
		mountains_sprites.append(sprite)
	
	print("   Created ", sprites_needed, " mountains sprites")

func create_middle_sprites():
	"""Create sprite nodes for middle layer textures"""
	if middle_textures.is_empty():
		return
		
	# Use the first texture for the middle layer
	var texture = middle_textures[0]
	
	# Calculate scaling and dimensions
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()
	var scale_factor = (screen_height * 0.8) / texture_height
	var scaled_width = texture_width * scale_factor
	
	# Create enough sprites to cover screen width + extra for scrolling
	var sprites_needed = int(ceil((screen_width * 3) / scaled_width)) + 1
	
	for i in range(sprites_needed):
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position.x = i * scaled_width
		sprite.position.y = screen_height / 2 + middle_vertical_offset
		sprite.centered = true
		
		middle_layer.add_child(sprite)
		middle_sprites.append(sprite)
	
	print("   Created ", sprites_needed, " middle layer sprites")

func create_placeholder_mountains():
	"""Create placeholder mountains for testing when no textures are provided"""
	var placeholder = ColorRect.new()
	placeholder.size = Vector2(screen_width * 3, screen_height)
	placeholder.position = Vector2(-screen_width, 0)
	placeholder.color = Color(0.2, 0.15, 0.25, 1.0)  # Dark purple/gray for post-apocalyptic sky
	mountains_layer.add_child(placeholder)
	
	# Add some simple mountain silhouettes
	for i in range(8):
		var mountain = ColorRect.new()
		mountain.size = Vector2(300 + randf() * 200, 150 + randf() * 100)
		mountain.position = Vector2(i * 400 - screen_width, screen_height - mountain.size.y)
		mountain.color = Color(0.1, 0.1, 0.15, 0.8)
		mountains_layer.add_child(mountain)
	
	print("   Created placeholder mountains elements")

func create_placeholder_middle():
	"""Create placeholder middle layer for testing when no textures are provided"""
	if not enable_middle_layer:
		return
		
	# Create some mid-distance rocky formations
	for i in range(12):
		var rock = ColorRect.new()
		rock.size = Vector2(80 + randf() * 120, 60 + randf() * 80)
		rock.position = Vector2(i * 250 - screen_width, screen_height - rock.size.y - randf() * 100)
		rock.color = Color(0.3, 0.25, 0.2, 0.6)
		middle_layer.add_child(rock)
	
	print("   Created placeholder middle layer elements")

func _process(delta):
	"""Update parallax scrolling based on world movement"""
	# Calculate movement distances for each layer
	var mountains_move_distance = world_movement_speed * mountains_scroll_speed * delta
	var middle_move_distance = world_movement_speed * middle_scroll_speed * delta
	
	# Update scroll positions
	mountains_scroll_position -= mountains_move_distance
	middle_scroll_position -= middle_move_distance
	
	# Debug output (remove after testing)
	if Engine.get_process_frames() % 60 == 0:  # Print once per second
		print("🏔️ Parallax Debug - Mountains pos: ", int(mountains_scroll_position), " | Mid pos: ", int(middle_scroll_position))
	
	# Move mountains layer
	if mountains_layer:
		mountains_layer.position.x = mountains_scroll_position
		
		# Handle wrapping for seamless scrolling
		if not mountains_sprites.is_empty():
			var texture = mountains_textures[0] if not mountains_textures.is_empty() else null
			if texture:
				var texture_width = texture.get_width()
				var scale_factor = screen_height / texture.get_height()
				var scaled_width = texture_width * scale_factor
				
				# Reset position when we've scrolled one full texture width
				if mountains_scroll_position <= -scaled_width:
					mountains_scroll_position += scaled_width
	
	# Move middle layer
	if middle_layer and enable_middle_layer:
		middle_layer.position.x = middle_scroll_position
		
		# Handle wrapping for seamless scrolling
		if not middle_sprites.is_empty():
			var texture = middle_textures[0] if not middle_textures.is_empty() else null
			if texture:
				var texture_width = texture.get_width()
				var scale_factor = (screen_height * 0.8) / texture.get_height()
				var scaled_width = texture_width * scale_factor
				
				# Reset position when we've scrolled one full texture width
				if middle_scroll_position <= -scaled_width:
					middle_scroll_position += scaled_width

func set_world_movement_speed(new_speed: float):
	"""Update world movement speed (called from game when speed changes)"""
	world_movement_speed = new_speed
	print("🏔️  Parallax: Updated world movement speed to ", world_movement_speed)

func toggle_middle_layer(enabled: bool):
	"""Enable or disable middle layer for performance/artistic reasons"""
	enable_middle_layer = enabled
	if middle_layer:
		middle_layer.visible = enabled
	print("🏔️  Parallax: Middle layer ", "enabled" if enabled else "disabled")

func get_mountains_scroll_speed() -> float:
	"""Get current mountains scroll speed in pixels per second"""
	return world_movement_speed * mountains_scroll_speed

func get_middle_scroll_speed() -> float:
	"""Get current middle layer scroll speed in pixels per second"""
	return world_movement_speed * middle_scroll_speed if enable_middle_layer else 0.0

func set_mountains_vertical_offset(offset: float):
	"""Update mountains layer vertical offset"""
	mountains_vertical_offset = offset
	# Update existing mountains sprites
	for sprite in mountains_sprites:
		sprite.position.y = screen_height / 2 + mountains_vertical_offset
	print("🏔️  Mountains vertical offset set to: ", offset)

func set_middle_vertical_offset(offset: float):
	"""Update middle layer vertical offset"""
	middle_vertical_offset = offset
	# Update existing middle layer sprites
	for sprite in middle_sprites:
		sprite.position.y = screen_height / 2 + middle_vertical_offset
	print("🏔️  Middle layer vertical offset set to: ", offset)
