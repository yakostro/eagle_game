# Start Scene & Scene Management Architecture

## High-Level Concept
Create a professional scene management system for "The Last Eagle" that supports the current start scene and future game over scene. The design should maintain the grim, post-apocalyptic atmosphere while providing smooth user experience transitions.

## Architecture Components

### 1. Scene Manager (Global Singleton)
**Purpose**: Centralized scene transition management
**Location**: Create as AutoLoad/Singleton

**Core Functions**:
- `change_scene(scene_path: String, transition_type: String = "fade")`
- `reload_current_scene()`
- `get_current_scene_name() -> String`
- Handles fade in/out transitions
- Manages loading states
- Future-proof for save/load functionality

### 2. Start Scene Structure
**Scene Path**: `scenes/start_scene.tscn`

**Node Hierarchy**:
```
StartScene (Control or Node2D)
├── BackgroundLayer (CanvasLayer, layer = -10)
│   └── BackgroundImage (TextureRect or Sprite2D)
├── UILayer (CanvasLayer, layer = 10) [exempt from palette shader]
│   └── UIContainer (Control)
│       ├── PressAnyButtonLabel (Label)
│       └── [Future: GameTitle, Credits, Options]
└── AudioController (Node)
    └── BackgroundMusic (AudioStreamPlayer)
```

### 3. Start Scene Script Components

**StartScene Script**:
- Extends Node or Control
- `@export var background_music: AudioStream` (inspector configurable)
- `@export var enable_background_music: bool = true`
- Universal input detection (any key/mouse button)
- Scene transition to `"res://scenes/game.tscn"`

**Input Detection**:
- Monitor `_unhandled_input()` for ANY input event
- Include keyboard keys, mouse buttons, gamepad buttons
- Add small delay to prevent accidental double-triggers
- Visual/audio feedback on input detection

### 4. Visual Design Guidelines

**Background Image**:
- Large atmospheric image showing post-apocalyptic landscape
- Should work with your limited color palette system
- Resolution: Design for your target screen size
- Style: Consistent with the grim, desolate mood

**UI Text**:
- Position: Bottom center of screen
- Text: "Press any button to start"
- Font: Readable, fits post-apocalyptic theme
- Color: High contrast against background
- Optional: Subtle fade in/out animation

### 5. Audio Integration

**Background Music**:
- Optional ambient/atmospheric track
- Should complement existing wind sound system
- Export variable in inspector for easy swapping
- Volume: Lower than game sounds, atmospheric
- Loop: Seamless looping for extended stays on start screen

## Future Extensions

### Game Over Scene Architecture
**When implementing Game Over scene**:
- Follow same structure as Start Scene
- Add score display integration
- Include restart/quit options
- Reuse Scene Manager for transitions

### Additional Scenes Support
- Scene Manager easily extends to support:
  - Settings/Options screen
  - Credits screen
  - Loading screens
  - Pause menu transitions

## Coding Agent Prompt

**High-Level Task**: Implement a start scene with comprehensive scene management system for "The Last Eagle" eagle survival game.

**Technical Decisions**:
1. Create AutoLoad SceneManager singleton for all scene transitions
2. Build StartScene using CanvasLayer structure for proper UI layering
3. Implement universal input detection system (_unhandled_input)
4. Add optional background music with inspector export variables
5. Use Control nodes for UI to ensure proper scaling
6. Position "Press any button to start" text at bottom center
7. Transition to "res://scenes/game.tscn" on any input
8. Ensure UI layer exempt from color palette shader (CanvasLayer layer = 10)

**Key Implementation Points**:
- Scene Manager handles smooth fade transitions
- Input detection includes keyboard, mouse, and future gamepad support
- Background image positioned in lower CanvasLayer for palette shader processing
- Audio system integrates with existing wind sound architecture
- Code structure supports future Game Over scene implementation
- All export variables properly configured for designer tweaking

**Testing Requirements**:
- Verify scene transition to main game works
- Test input detection with various input methods
- Confirm UI remains unaffected by color palette shader
- Validate audio plays correctly when enabled
