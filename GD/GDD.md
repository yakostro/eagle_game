
# Game concept. The Last Eagle

# Story and world
## Story:

there is a postapocalyptic world and a lot of species are about to extinct. there are the last adult eagle left and a lot of abandoned nests with hungry eagle chicks. The only mission of this exhausted bald eagle is to feed this chicks and hope that the specie will survive even at a price of it’s own life

## Mood and feel:
- Grim mood
- ‘Morale’ parameter is a key. Player has to realize how BAD actually the missing nest is. It’s a key.
	- We should show it super explicitly to user and the influence should be visible and feelable.
	- When the nest appear. Show user that nest is important.


*Aim*: You play as the last eagle whose mission is to feed eagle chicks so the species can survive
Core gameplay: fly, evade obstacles, catch fish, feed chicks to get morale or eat fish to get energy, keep balance between morale and energy. The difficulty (obstacles, quantity of fish) raises through time
Lose: if energy drops to 0
Score: count how many chicks survived
Eagle Flies through the terrain. Side view.
Eagle is controlled by the player


Detailed description
# Eagle
## Eagle movement and controls
- Eagle can move UP an DOWN
	- To move Up: W and UP_ARROW
	- To move Down: S and DOWN ARROW
- No gravity applied to the eagle

## States
- IDLE
- CHANGING_POSITION
- HIT
- SCREECH
- DIE

Parameters:
has_fish


## Catch fish
- When eagle collides with fish and has no fish in claws, he catches it
- If caught, fish sit in the claws of the eagle. It rotates with the eagle rotation
- Eagle can carry only one fish at a time
- if eagle already has a fish and fish collides with the eagle, then fish is just continue moving 

## Release fish
- If eagle has fish in his claws he can release it
- Player presses F to release a fish

## Eat fish
- When player press E button on the keyboard AND an eagle has a fish, an eagle eats a fish
- Make a signal for this event so fish could disappear and UI animation about adding energy could be played
- Add energy (from fish’s parameter) to the eagle

## Hit
- When eagle collides with the obstacle, it loses part of his energy
- Eagle is not interacting with the obstacles like a physical body
- Eagle blinks for a while and become immune to collisions for amount of time like in old-style games
- play animation 'hit' and then get back to the animation state that corresponds to eagle movement state. The blinking could last longer than 'hit' animation
- when eagle hit obstacle and has fish, 'drop fish' behavior  should be activated
- when the eagle is hit by enemy bird it looses energy corresponding to the value defined in the bird script (default 20 energy points)


# Morale and energy
Energy
- Energy loses overtime
- Make a energy_lose_points variable how much it lose in a sec
- Energy_lose_points increased if the morale points goes down, so the less the morale is the faster an eagle lose his energy
- When an eagle eats a fish - fish energy is added to the current energy. Energy defined in a particular fish
- When an eagle hit an obstacle (tree, mountain, island, bullet etc), he losses amount of energy (defined by the obstacle)
- When energy is 0, eagle dies

Morale
- When a NEST goes off screen without being fed, an eagle lose morale points
- Morale can't go below 0
- If morale is 0 eagle can still fly


# Fish
## Instantiation
- Fish spawns on the right from the eagle below the bottom of the screen
- Fish jumps to the left towards eagle
- Each fish jumps with slightly different velocity and angle
- Gravity is applied to a fish
- Fish has an energy const. It will be added to the eagle energy when eaten

## Caught
- Fish sits in the claws
- No gravity or collision applied to fish

## Released
- Fish starts to fall down with gravity applied
- If it goes below the screen - delete an instance

## Fed
- If fish collides with a NEST it disappears
- Add signal for UI to play positive feedback animation

## Eaten
- Fish disappears from the claws 
- Add an energy to the eagle

Obstacles:
## Instantiation
- Make one spawner for all obstacles (fish is not an obstacle)
- Obstacle spawns once in a while (make export var)
- there are several types of obstacles
- the spawner chose what type of obstacle will be placed
- Placed on the right side of the screen outside the screen 
- Moves to the left with the speed of an eagle (use the same 'eagle/world speed' variable for all moving obstacles)
- At some obstacles could be spawn a nest
- Nest could be spawn on the obstacles where the 'NestPlaceholder' is. Maybe it's worth to add a parameter determining is nest could be placed for the obstacle

## Obstacle types:
- Mountain
- Stalactite
- Floating Island
- [Then will be added more...]

# Mountain
- When instantiated mountain should be placed at a random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset. offset is a variable and == 500 px 
- Uses **height parameters**: `mountain_min_height` and `mountain_max_height` (measured from screen bottom)

# Stalactite
- When instantiated stalactite should be placed at a random Y position: from -sprite_height + minimum_stalactite_height to 0
- The nest could not be placed at the stalactite
- Uses **height parameters**: `stalactite_min_height` and `stalactite_max_height` (measured from screen top, negative values)

# Floating Island
- When instantiated floating island should be placed at a random Y position: from `minimum_top_offset` to `minimum_bottom_offset + sprite_height`
- Uses **offset parameters**: `floating_island_minimum_top_offset` and `floating_island_minimum_bottom_offset`
- Default values: `minimum_top_offset = 500`, `minimum_bottom_offset = 300`
- Offsets define safe zones from screen edges where islands can spawn

# Nest
## Instantiation
- Nest spawns once on every N (make a export var) obstacle
- nest placed inside the obstacle scene in the Marker2d 'NestPlaceholder'
- Spawn at random mountain within min and max interval. 
- Increase difficulty > more rare nest spawn.

## States
- Hungry
- Fed

## Hungry state
- plays hungry animation
- If a nest collides with the fish:
	- It emits signal for eagle to increase moral points
	- Nest switched to Fed state
	- the sprite that is used in the fish is placed into the FishPlaceholder in the nest scene. preserve position, scale and rotation that fish sprite has before get into the nest
	- fish should be fed to nest ONLY if it was dropped from the eagle. otherwise it shouldn't be fed

## Fed state
- plays fed animation


## Behavior (for any state)
- If nest goes off the left side of the screen, it emits a signal for the eagle to decrease moral points. Also the instance of the nest is deleted
- the world should be bigger than camera view and eagle shoul be able to move bot and top quite actively

Enemies:
- make a enemies spawner that will control spawn of different enemy types.

# Enemy types:
- enemy bird

# Enemy bird
## Instantiate
- enemy bird is spawned on the right side of the screen
- it spawned once in a while (make a var)
- should be progression in difficulty 

## Movement
- when spawned enemy bird moves towards the eagle Y position by curve and tries to hit an eagle.
- bird moves with the acceleration
- if the eagle change its position, enemy bird tries to make it’s new trajectory towards his new Y position but it has a limitation - the speed of change direction (make a ver)
- birds fly through the eagle and not stop on the eagle's X coordinate, they just continue moving towarsds left edge of the screen.
- if an enemy bird hit the eagle it continue move with the same direction as it moved before and goes off the screen on a left side
- When bird's X more than eagle's X - bird shouldnt consider eagle's change position 
at all
- birds must not collide and interact with the eagle, just check for collision

## Misc
- I have EnemyBird.tscn character body 2d with a sprite and collision capsule
- when  enemy bird goes off screen it is  removed from the game


# Art Direction
## Limited Color Palette System
- The entire game uses a limited color palette enforced through a global post-processing shader
- Uses DawnBringer 16 (DB16) palette by default: 16 carefully chosen colors that work well together
- Palette is applied via screen-space shader that:
  - Remaps all rendered colors to the nearest palette color
  - Uses ordered dithering (4x4 Bayer matrix) to reduce color banding
  - Processes game world but excludes UI (UI rendered in higher CanvasLayer)
- Configurable parameters:
  - `palette_size`: Number of colors in palette (1-64)
  - `use_dither`: Enable/disable dithering effect
  - `dither_strength`: Intensity of dithering pattern
  - `saturation`, `contrast`, `brightness`: Color adjustments before palette mapping
- Benefits:
  - Unified art style across all sprites and backgrounds
  - Retro/pixel art aesthetic without requiring pixel-perfect artwork
  - Easy to experiment with different color schemes
  - Performance-friendly single-pass effect

# Parallax Background System
## Three-Layer Parallax Structure
The game uses a sophisticated 3-layer parallax background system that creates depth and atmosphere:

### Layer 1: Gradient Background (Furthest)
- **Purpose**: Provides atmospheric sky/horizon backdrop
- **Movement**: Static or very slow scroll (0.0 speed multiplier by default)
- **Implementation**: Configurable gradient from top color to bottom color
- **Z-index**: -40 (furthest back)
- **Configuration**: 
  - `gradient_top_color`: Sky color (default: dark purple-gray)
  - `gradient_bottom_color`: Horizon color (default: slightly lighter)
  - `enable_gradient_layer`: Toggle on/off

### Layer 2: Mountain Layer (Middle Distance)
- **Purpose**: Distant terrain silhouettes (mountains, hills)
- **Movement**: Slow parallax scroll (0.1 speed multiplier)
- **Implementation**: Repeating sprite textures or placeholder mountain shapes
- **Z-index**: -30 (middle depth)
- **Textures**: Uses `mountain_textures` array or creates placeholder mountains
- **Configuration**:
  - `mountain_scroll_speed`: Parallax speed multiplier
  - `mountain_vertical_offset`: Vertical positioning adjustment
  - `mountain_transparency`: Transparency level (0.0 = invisible, 1.0 = opaque)
  - `enable_mountain_layer`: Toggle on/off

### Layer 3: Mid Layer (Closest)
- **Purpose**: Mid-distance environmental elements (rocks, debris, structures)
- **Movement**: Faster parallax scroll (0.4 speed multiplier)
- **Implementation**: Repeating sprite textures or placeholder elements
- **Z-index**: -20 (closest parallax layer)
- **Textures**: Uses `middle_textures` array or creates placeholder rocks
- **Configuration**:
  - `middle_scroll_speed`: Parallax speed multiplier
  - `middle_vertical_offset`: Vertical positioning adjustment
  - `middle_transparency`: Transparency level (0.0 = invisible, 1.0 = opaque)
  - `enable_middle_layer`: Toggle on/off

## Parallax System Features
- **Seamless Scrolling**: All layers wrap seamlessly for infinite scrolling
- **Performance Optimization**: Individual layers can be toggled for performance
- **Dynamic Configuration**: Colors, speeds, and offsets can be adjusted at runtime
- **Transparency Control**: Each layer supports individual transparency settings with smooth fading
- **World Speed Sync**: All movement synced with main game world movement speed
- **Depth Illusion**: Proper speed ratios create convincing depth perception

## Technical Implementation
- **Script**: `ParallaxBackgroundSystem` class in `scripts/systems/parallax_background_system.gd`
- **Dependencies**: Syncs with obstacle system world movement speed
- **Texture Support**: Each layer supports texture arrays or procedural generation
- **Debug Support**: Built-in debug output for position tracking

Sounds
# ambient
- I have embient sound node in the game scene.
- And two wind sounds. I want to intermix them.
- wind_woosh_loop.ogg should be the basic.
- additional_wind.wav should be mixed time to time. different parts of it like a span from 5 to 8 sec. and the next time - another part of this audio. with fade.

# Scene Management & UI Flow

## Start Scene
- **Purpose**: Entry point for the game, sets atmospheric tone
- **Visual**: Large background image showing post-apocalyptic landscape
- **UI**: "Press any button to start" text at bottom center
- **Input**: Universal input detection (any keyboard key, mouse button, or gamepad)
- **Audio**: Optional background music (configurable in inspector)
- **Transition**: Leads to main game scene (game.tscn)

## Scene Flow Architecture
```
Start Scene → Main Game → Game Over Scene → [Back to Start Scene]
```

## Game Over Scene (Future)
- Will display final score (chicks survived)
- Options to restart or return to start screen
- Maintains same atmospheric visual design
- Uses centralized Scene Manager for transitions

## Technical Architecture
- **Scene Manager**: Global singleton handles all scene transitions with fade effects (IMPLEMENTED)
- **UI Layering**: UI elements exempt from color palette shader using CanvasLayer layer 10 (IMPLEMENTED)
- **Audio Integration**: Background music complements wind sound system with configurable volume (IMPLEMENTED)
- **Input System**: Universal input detection across all scenes including keyboard, mouse, and gamepad (IMPLEMENTED)

## Implementation Status
- ✅ Scene Manager AutoLoad singleton with smooth fade transitions
- ✅ Start Scene with proper CanvasLayer structure (Background layer -10, UI layer 10)
- ✅ Universal input detection system responding to any key/mouse/gamepad input
- ✅ Project configured to launch with start scene as entry point
- ✅ Audio system integration with inspector-configurable background music

# Stage-Based Balancing System

## Overview
The game implements a comprehensive stage-based difficulty progression system that controls all spawning parameters and world behavior through predefined stages, followed by an automatic difficulty scaling mechanism for infinite gameplay.

## Stage System
The game progresses through 6 manually-designed stages, each introducing new mechanics and gradually increasing difficulty:

### Stage 1: Introduction (10 seconds)
- Mountains + Islands only
- No fish, no nests
- Slow movement speed
- Purpose: Basic movement and obstacle avoidance

### Stage 2: Fish Introduction (5 seconds)  
- Mountains + Islands
- Fish spawning enabled
- No nests
- Purpose: Learn fish catching mechanics

### Stage 3: Nest Introduction (Until 2 nests spawned)
- Mountains + Islands
- Fish enabled
- Nests enabled (frequent spawning)
- Purpose: Learn nest feeding mechanics

### Stage 4: Stalactite Introduction (Until 3 nests spawned)
- All obstacle types introduced
- Higher mountains, closer spacing
- Increased world speed
- Purpose: Full obstacle variety

### Stage 5: Increased Difficulty (Until 5 nests spawned)
- Balanced obstacle weights
- Faster fish spawning
- Less frequent nests
- Higher world speed

### Stage 6: Final Manual Stage (Until 10 nests spawned)
- Maximum manual difficulty
- Transition point to automatic system

## Automatic Difficulty System
After Stage 6, an automatic progression system activates:
- Percentage-based parameter increases every 30 seconds
- World speed increases by 5% per interval (capped at 2x)
- Spawn rates increase by 10% per interval
- Obstacle distances decrease by 5% per interval
- Stalactite weight increases over time
- All increases have safety caps to prevent impossible difficulty

## Configurable Parameters Per Stage
- World/eagle movement speed
- Obstacle type weights (mountain, stalactite, floating island)
- Obstacle positioning: height ranges for mountains/stalactites, offset parameters for floating islands
- Obstacle distance ranges (min/max)
- Chance for same obstacle type to repeat
- Fish spawn intervals (min/max)
- Nest skip intervals (min/max obstacles)
- Stage completion conditions (timer or nest count)

## Technical Implementation
- **StageManager**: Central singleton controlling stage progression
- **StageConfiguration**: Resource files (.tres) for each stage's parameters
- **AutoDifficultySystem**: Percentage-based parameter modification
- **Spawner Integration**: All spawners (obstacle, fish, nest) accept stage parameters
- **Data-Driven**: Easy tweaking through Godot editor without code changes

## Benefits
- **Progressive Learning**: Each stage introduces one new concept
- **Smooth Difficulty Curve**: No sudden spikes or impossible sections  
- **Infinite Gameplay**: Auto-system ensures continued challenge
- **Designer-Friendly**: Parameters easily adjustable in editor
- **Player Feedback**: Clear stage transitions and progress indicators

**Status**: 📋 Design Complete - Implementation Tasks Ready

**Implementation Guide**: See `stage_system_implementation_tasks.md` for detailed step-by-step implementation tasks (15 focused tasks, each independently testable) 
