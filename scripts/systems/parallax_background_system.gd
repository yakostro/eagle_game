extends Node2D

class_name ParallaxBackgroundSystem

## Parallax Background System for "The Last Eagle"
## Creates atmospheric depth through three-layer parallax scrolling
## Layer 1 (furthest): Gradient background
## Layer 2 (middle): Mountains/distant terrain
## Layer 3 (closest): Mid-distance elements
## Syncs with existing world movement speed from obstacle system
## Custom implementation that doesn't rely on ParallaxBackground

# Configuration variables as per design document
@export_group("Layer Configuration")
@export var enable_gradient_layer: bool = true
@export var enable_mountain_layer: bool = true
@export var enable_middle_layer: bool = true
@export var gradient_scroll_speed: float = 0.0  # Multiplier for world speed (gradient - usually static)
@export var mountain_scroll_speed: float = 0.1  # Multiplier for world speed (distant mountains)
@export var middle_scroll_speed: float = 0.4  # Multiplier for world speed (mid-distance)

@export_group("Layer Positioning")
@export var gradient_vertical_offset: float = 0.0  # Vertical offset for gradient layer (+ = down, - = up)
@export var mountain_vertical_offset: float = 0.0  # Vertical offset for mountain layer (+ = down, - = up)
@export var middle_vertical_offset: float = 50.0  # Vertical offset for middle layer (+ = down, - = up)

@export_group("Layer Visual Effects")
@export_range(0.1, 5.0) var mountain_scale: float = 1.0  # Mountain background sprite scale (inspector controllable)
@export_range(0.0, 1.0) var mountain_transparency: float = 1.0  # Mountain layer transparency (0 = invisible, 1 = opaque)
@export_range(0.0, 1.0) var middle_transparency: float = 1.0  # Middle layer transparency (0 = invisible, 1 = opaque)

@export_group("Gradient Configuration")
@export var gradient_top_color: Color = Color(0.15, 0.1, 0.2, 1.0)  # Top gradient color (sky)
@export var gradient_bottom_color: Color = Color(0.3, 0.2, 0.25, 1.0)  # Bottom gradient color

@export_group("Layer Textures")
@export var mountain_textures: Array[Texture2D] = []  # For mountain layer
@export var middle_textures: Array[Texture2D] = []  # For middle layer

@export_group("World Movement Integration")
@export var world_movement_speed: float = 300.0  # Should match obstacle_movement_speed

# Layer references (simple Node2D containers)
var gradient_layer: Node2D
var mountain_layer: Node2D
var middle_layer: Node2D

# Sprite/visual nodes for each layer
var gradient_rect: TextureRect
var mountain_sprites: Array[Sprite2D] = []
var middle_sprites: Array[Sprite2D] = []

# Screen dimensions
var screen_width: float
var screen_height: float

# Movement tracking
var gradient_scroll_position: float = 0.0
var mountain_scroll_position: float = 0.0
var middle_scroll_position: float = 0.0

# Cached widths to avoid per-frame texture queries/computations
var _mountain_texture_scaled_width: float = 0.0
var _middle_texture_scaled_width: float = 0.0

func _ready():
	# Get screen dimensions
	screen_width = get_viewport().get_visible_rect().size.x
	screen_height = get_viewport().get_visible_rect().size.y
	
	# Set up parallax layers (furthest to closest)
	if enable_gradient_layer:
		setup_gradient_layer()
	if enable_mountain_layer:
		setup_mountain_layer()
	if enable_middle_layer:
		setup_middle_layer()
	

func setup_gradient_layer():
	"""Create and configure the gradient layer (furthest background)"""
	gradient_layer = Node2D.new()
	gradient_layer.name = "GradientLayer"
	gradient_layer.z_index = -40  # Furthest behind everything
	add_child(gradient_layer)
	
	# Create gradient background using TextureRect
	var gradient_texture_rect = TextureRect.new()
	gradient_texture_rect.size = Vector2(screen_width * 3, screen_height)
	gradient_texture_rect.position = Vector2(-screen_width, 0)
	
	# Create gradient material
	var gradient = Gradient.new()
	gradient.set_color(0, gradient_top_color)
	gradient.set_color(1, gradient_bottom_color)
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)
	
	gradient_texture_rect.texture = gradient_texture
	gradient_layer.add_child(gradient_texture_rect)
	
	# Store reference for later updates
	gradient_rect = gradient_texture_rect


func setup_mountain_layer():
	"""Create and configure the mountain layer (distant mountains/terrain)"""
	mountain_layer = Node2D.new()
	mountain_layer.name = "MountainLayer"
	mountain_layer.z_index = ZOrder.PARALLAX_MOUNTAINS  # Behind middle layer, in front of gradient
	mountain_layer.modulate.a = mountain_transparency  # Apply transparency
	add_child(mountain_layer)
	
	# Create sprites for mountain textures
	if not mountain_textures.is_empty():
		create_mountain_sprites()
	else:
		create_placeholder_mountains()

func setup_middle_layer():
	"""Create and configure the middle layer (mid-distance elements)"""
	middle_layer = Node2D.new()
	middle_layer.name = "MiddleLayer"
	middle_layer.z_index = ZOrder.PARALLAX_MIDDLE  # Between background and foreground
	middle_layer.modulate.a = middle_transparency  # Apply transparency
	add_child(middle_layer)
	
	# Create sprites for middle textures
	if not middle_textures.is_empty():
		create_middle_sprites()
	else:
		create_placeholder_middle()

func create_mountain_sprites():
	"""Create sprite nodes for mountain textures"""
	if mountain_textures.is_empty():
		return
		
	# Use the first texture for the mountains
	var texture = mountain_textures[0]
	
	# Calculate scaling and dimensions using inspector-controllable scale
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()
	var scale_factor = mountain_scale  # Use the inspector-controllable scale
	var scaled_width = texture_width * scale_factor
	var scaled_height = texture_height * scale_factor
	_mountain_texture_scaled_width = scaled_width
	
	# Create enough sprites to cover screen width + extra for scrolling
	var sprites_needed = int(ceil((screen_width * 3) / scaled_width)) + 1
	
	for i in range(sprites_needed):
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position.x = i * scaled_width
		# Position sprite so its bottom edge aligns with screen bottom (plus offset)
		sprite.position.y = screen_height - (scaled_height / 2) + mountain_vertical_offset
		sprite.centered = true
		
		mountain_layer.add_child(sprite)
		mountain_sprites.append(sprite)


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
	_middle_texture_scaled_width = scaled_width
	
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


func create_placeholder_mountains():
	"""Create placeholder mountains for testing when no textures are provided"""
	# Add some simple mountain silhouettes
	for i in range(8):
		var mountain = ColorRect.new()
		mountain.size = Vector2(300 + randf() * 200, 150 + randf() * 100)
		mountain.position = Vector2(i * 400 - screen_width, screen_height - mountain.size.y + mountain_vertical_offset)
		mountain.color = Color(0.1, 0.1, 0.15, 0.8)  # Dark mountain silhouettes
		mountain_layer.add_child(mountain)
	


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
	


func _process(delta):
	"""Update parallax scrolling based on world movement"""
	# Calculate movement distances for each layer
	var gradient_move_distance = world_movement_speed * gradient_scroll_speed * delta
	var mountain_move_distance = world_movement_speed * mountain_scroll_speed * delta
	var middle_move_distance = world_movement_speed * middle_scroll_speed * delta
	
	# Update scroll positions
	gradient_scroll_position -= gradient_move_distance
	mountain_scroll_position -= mountain_move_distance
	middle_scroll_position -= middle_move_distance
	

	# Move gradient layer (usually static, but can scroll very slowly)
	if gradient_layer and enable_gradient_layer:
		gradient_layer.position.x = gradient_scroll_position
	
	# Move mountain layer
	if mountain_layer and enable_mountain_layer:
		mountain_layer.position.x = mountain_scroll_position
		
		# Handle wrapping for seamless scrolling
		if not mountain_sprites.is_empty():
			# Reset position when we've scrolled one full texture width
			var width = _mountain_texture_scaled_width
			if width <= 0.0 and not mountain_textures.is_empty():
				# Fallback compute once if cache not ready yet
				var texture = mountain_textures[0]
				width = texture.get_width() * mountain_scale
				_mountain_texture_scaled_width = width
			if width > 0.0 and mountain_scroll_position <= -width:
				mountain_scroll_position += width
	
	# Move middle layer
	if middle_layer and enable_middle_layer:
		middle_layer.position.x = middle_scroll_position
		
		# Handle wrapping for seamless scrolling
		if not middle_sprites.is_empty():
			# Reset position when we've scrolled one full texture width
			var width2 = _middle_texture_scaled_width
			if width2 <= 0.0 and not middle_textures.is_empty():
				var texture2 = middle_textures[0]
				var scale2 = (screen_height * 0.8) / texture2.get_height()
				width2 = texture2.get_width() * scale2
				_middle_texture_scaled_width = width2
			if width2 > 0.0 and middle_scroll_position <= -width2:
				middle_scroll_position += width2

func set_world_movement_speed(new_speed: float):
	"""Update world movement speed (called from game when speed changes)"""
	world_movement_speed = new_speed


func toggle_gradient_layer(enabled: bool):
	"""Enable or disable gradient layer"""
	enable_gradient_layer = enabled
	if gradient_layer:
		gradient_layer.visible = enabled


func toggle_mountain_layer(enabled: bool):
	"""Enable or disable mountain layer for performance/artistic reasons"""
	enable_mountain_layer = enabled
	if mountain_layer:
		mountain_layer.visible = enabled


func toggle_middle_layer(enabled: bool):
	"""Enable or disable middle layer for performance/artistic reasons"""
	enable_middle_layer = enabled
	if middle_layer:
		middle_layer.visible = enabled


func get_gradient_scroll_speed() -> float:
	"""Get current gradient scroll speed in pixels per second"""
	return world_movement_speed * gradient_scroll_speed if enable_gradient_layer else 0.0

func get_mountain_scroll_speed() -> float:
	"""Get current mountain scroll speed in pixels per second"""
	return world_movement_speed * mountain_scroll_speed if enable_mountain_layer else 0.0

func get_middle_scroll_speed() -> float:
	"""Get current middle layer scroll speed in pixels per second"""
	return world_movement_speed * middle_scroll_speed if enable_middle_layer else 0.0

func set_gradient_vertical_offset(offset: float):
	"""Update gradient layer vertical offset"""
	gradient_vertical_offset = offset
	if gradient_rect:
		gradient_rect.position.y = gradient_vertical_offset


func set_mountain_vertical_offset(offset: float):
	"""Update mountain layer vertical offset"""
	mountain_vertical_offset = offset
	# Update existing mountain sprites to maintain bottom-edge alignment
	for sprite in mountain_sprites:
		if sprite.texture:
			var scaled_height = sprite.texture.get_height() * mountain_scale
			sprite.position.y = screen_height - (scaled_height / 2) + mountain_vertical_offset


func set_middle_vertical_offset(offset: float):
	"""Update middle layer vertical offset"""
	middle_vertical_offset = offset
	# Update existing middle layer sprites
	for sprite in middle_sprites:
		sprite.position.y = screen_height / 2 + middle_vertical_offset


func update_gradient_colors(top_color: Color, bottom_color: Color):
	"""Update gradient colors dynamically"""
	gradient_top_color = top_color
	gradient_bottom_color = bottom_color
	
	if gradient_rect and gradient_rect.texture is GradientTexture2D:
		var gradient_texture = gradient_rect.texture as GradientTexture2D
		gradient_texture.gradient.set_color(0, gradient_top_color)
		gradient_texture.gradient.set_color(1, gradient_bottom_color)


# Backward compatibility functions for existing code
func get_background_scroll_speed() -> float:
	"""Legacy function - now maps to mountain layer speed for backward compatibility"""
	return get_mountain_scroll_speed()

func set_background_vertical_offset(offset: float):
	"""Legacy function - now maps to mountain layer offset for backward compatibility"""
	set_mountain_vertical_offset(offset)

func set_mountain_transparency(transparency: float):
	"""Set mountain layer transparency (0.0 = invisible, 1.0 = opaque)"""
	mountain_transparency = clamp(transparency, 0.0, 1.0)
	if mountain_layer:
		mountain_layer.modulate.a = mountain_transparency


func set_middle_transparency(transparency: float):
	"""Set middle layer transparency (0.0 = invisible, 1.0 = opaque)"""
	middle_transparency = clamp(transparency, 0.0, 1.0)
	if middle_layer:
		middle_layer.modulate.a = middle_transparency


func set_mountain_scale(new_scale: float):
	"""Update mountain layer scale and reposition sprites to maintain bottom-edge alignment"""
	mountain_scale = clamp(new_scale, 0.1, 5.0)
	
	# Update existing mountain sprites
	for sprite in mountain_sprites:
		if sprite.texture:
			sprite.scale = Vector2(mountain_scale, mountain_scale)
			var scaled_height = sprite.texture.get_height() * mountain_scale
			sprite.position.y = screen_height - (scaled_height / 2) + mountain_vertical_offset
			_mountain_texture_scaled_width = sprite.texture.get_width() * mountain_scale


func fade_mountain_layer(target_transparency: float, duration: float):
	"""Smoothly fade mountain layer to target transparency over specified duration"""
	if not mountain_layer:
		return
	
	var tween = create_tween()
	tween.tween_method(set_mountain_transparency, mountain_transparency, target_transparency, duration)


func fade_middle_layer(target_transparency: float, duration: float):
	"""Smoothly fade middle layer to target transparency over specified duration"""
	if not middle_layer:
		return
	
	var tween = create_tween()
	tween.tween_method(set_middle_transparency, middle_transparency, target_transparency, duration)

