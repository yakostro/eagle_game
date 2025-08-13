# Parallax Background System Design

## High Level Concept

Create a **two-layer parallax background system** for "The Last Eagle" that enhances the post-apocalyptic mountainous world depth and immersion. The system should provide atmospheric depth while maintaining the grim, twilight mood of the game.

### Visual Layers Architecture:
1. **Background Layer** (Far Distance) - Always active
2. **Middle Layer** (Mid Distance) - Optional, can be disabled

## Game Design Requirements

### Background Layer (Required)
- **Purpose**: Distant mountains, sky, and apocalyptic horizon elements
- **Visual Elements**: 
  - Distant mountain silhouettes
  - Apocalyptic sky with twilight lighting
  - Far background debris/ruins
  - Atmospheric haze effects
- **Movement Speed**: 0.1-0.3x of game world speed (very slow parallax)
- **Art Style**: Follows limited color palette system, cold colors, grim mood

### Middle Layer (Optional)
- **Purpose**: Mid-distance environmental details
- **Visual Elements**:
  - Ruined structures
  - Dead trees
  - Rocky formations
  - Atmospheric particles
- **Movement Speed**: 0.5-0.7x of game world speed (medium parallax)
- **Toggle Feature**: Must be easily disabled for performance or artistic reasons

## Technical Architecture

### Scene Structure
- Create `ParallaxBackground.tscn` scene with modular components
- Use Godot's `ParallaxBackground` and `ParallaxLayer` nodes
- Implement configurable scrolling speeds and layer management

### Configuration System
- Export variables for easy designer control:
  - `enable_middle_layer: bool = true`
  - `background_scroll_speed: float = 0.2`
  - `middle_scroll_speed: float = 0.6`
  - `layer_textures: Array[Texture2D]` for different background sets

### Performance Considerations
- Efficient texture streaming for large backgrounds
- Memory management for texture resources
- Option to disable middle layer for lower-end devices

## Integration with Existing Systems

### World Movement
- Sync with eagle movement speed (world scrolling)
- Connect to existing obstacle/world speed variables
- Maintain consistent movement with game objects

### Art Pipeline
- Must work with existing limited color palette shader system
- Support for modular background asset creation
- Easy asset swapping for different areas/moods

## Developer Implementation Task

**High Level Task**: Create a flexible parallax background system that adds visual depth to the eagle's flight through the post-apocalyptic world while maintaining performance and artistic consistency.

**Technical Decision**: 
- Use Godot's built-in `ParallaxBackground` system with custom configuration wrapper
- Create modular layer system where middle layer can be completely disabled
- Implement smooth scrolling that syncs with existing world movement speed
- Ensure compatibility with limited color palette post-processing shader

**Key Implementation Points**:
1. Create reusable `ParallaxBackground.tscn` scene
2. Implement layer management script with export variables
3. Sync scrolling with existing eagle/world movement system
4. Provide easy toggle for middle layer activation/deactivation
5. Ensure textures work properly with existing color palette shader
6. Create example background assets that fit the game's art direction

**Integration Requirements**:
- Must not interfere with existing obstacle spawning system
- Should enhance the grim, post-apocalyptic atmosphere
- Performance impact should be minimal and configurable
- Easy for game designer to adjust speeds and enable/disable layers during development

## Art Requirements

### Background Layer Assets Needed:
- Distant mountain silhouettes (seamlessly tileable)
- Post-apocalyptic sky gradient
- Atmospheric haze elements
- Optional: Far ruins/debris silhouettes

### Middle Layer Assets Needed:
- Mid-distance rocky formations
- Dead tree silhouettes
- Ruined structure elements
- Atmospheric particles/dust

### Technical Specifications:
- All assets must work with DB16 color palette
- Textures should be optimized for horizontal tiling
- Resolution: Match game's target resolution requirements
- Format: PNG with transparency support where needed
