# ESC Menu & Pause System

## Overview
A pause menu system that allows players to pause the game, resume, restart, or quit. The menu provides a clear visual indication that the game is paused by dimming the game scene with a semi-transparent overlay.

## Game Design Goals
1. **Instant Feedback** - Player should immediately see the game freeze and menu appear
2. **Clear Visual State** - Dimmed overlay makes it obvious the game is paused
3. **Quick Access** - ESC key toggles pause on/off for fast resume
4. **Safety** - Prevent accidental actions during pause (no game input processed)

## User Experience Flow

### Opening Menu
1. Player presses ESC key
2. Game immediately freezes (all movement, spawning, physics stops)
3. Fade overlay appears with smooth fade-in animation (0.2s)
4. Menu buttons appear centered on screen
5. Game audio continues playing (atmospheric, not gameplay sounds)

### Closing Menu
1. Player presses ESC again OR clicks Resume button
2. Fade overlay smoothly fades out (0.2s)
3. Game unpauses and resumes exactly where it left off
4. Player regains full control

### Restart Action
1. Player clicks Restart button
2. Menu closes and game unpauses
3. GameManager.restart_game() is called
4. Game scene reloads from beginning
5. Stage progress resets to Stage 1
6. All game stats reset (fed nests, score, etc.)

### Quit Action
1. Player clicks Quit button
2. Game closes completely (get_tree().quit())
3. No confirmation dialog (player can always restart)

## Technical Architecture

### Scene Structure
```
UiEscMenu (Node2D) - Root node with script
├── UILayer (CanvasLayer, layer=10) - Always on top
    └── UIContainer (Control, full screen anchored)
        ├── FadeOverlay (ColorRect) - Semi-transparent dark overlay
        └── VBoxContainer (centered)
            ├── Resume (Button)
            ├── Restart (Button)
            └── Quit (Button)
```

### Component Responsibilities

**UiEscMenu Script:**
- Listen for ESC key input (always active, even when paused)
- Toggle pause state (get_tree().paused = true/false)
- Animate fade overlay (Tween alpha 0.0 ↔ 0.7)
- Handle button signals
- Set process_mode to PROCESS_MODE_ALWAYS (works during pause)

**FadeOverlay (ColorRect):**
- Color: Semi-transparent dark (Color(0.06, 0, 0.07, 0.7) at full opacity)
- Initial modulate.a = 0.0 (invisible)
- Tweened to modulate.a = 1.0 (visible overlay at 70% opacity)

**Buttons:**
- All use existing button styles (ui_button_default.tres, hover, pressed)
- Centered vertically with 20px spacing
- 300x80 minimum size for easy clicking

### Pause System Details

**What Gets Paused:**
- Eagle movement and physics
- All spawners (obstacles, fish, nests)
- Obstacle movement
- Fish movement
- Nest timers
- Stage progression timer
- Wind particles

**What Stays Active:**
- ESC menu input processing (process_mode = PROCESS_MODE_ALWAYS)
- UI rendering
- Background music (ambient atmosphere)
- Camera (stays in place)

**How Pausing Works:**
- Use Godot's built-in pause system: `get_tree().paused = true`
- All nodes with default process_mode (PROCESS_MODE_INHERIT) will pause
- ESC menu node must have `process_mode = PROCESS_MODE_ALWAYS` to work during pause

### Animation Timing
- **Fade In:** 0.2 seconds (quick response)
- **Fade Out:** 0.2 seconds (smooth exit)
- **Tween Type:** TRANS_CUBIC, EASE_OUT (smooth deceleration)

### Input Handling
- ESC key toggles menu (InputEventKey, keycode = KEY_ESCAPE)
- Only process ESC when game is active (not in game over or intro scenes)
- Resume button does same action as ESC toggle
- Mouse input for buttons (hover, click states)

## Integration Points

### GameManager Integration
- ESC menu should be added to main game scene (game.tscn)
- GameManager needs a dedicated `restart_game()` function
- ESC menu will call `GameManager.restart_game()` for restart button

**GameManager.restart_game() Function:**
- Unpause the game first (`get_tree().paused = false`)
- Reset game state flags (is_game_over = false)
- Reset GameStats (if exists)
- Reset StageManager to stage 1 (if exists)
- Use SceneManager.reload_current_scene() to reload the scene
- This ensures clean restart with all systems reset

**Why Dedicated Function:**
- Centralizes restart logic in one place
- Ensures proper cleanup before reload
- Can be reused by other systems (debug keys, game over screen)
- Handles unpause automatically (important for ESC menu restart)

### Scene Setup
1. Add UiEscMenu instance to game.tscn
2. Position doesn't matter (uses CanvasLayer)
3. Initially hidden (visible = false)
4. Script handles all show/hide logic
5. UiEscMenu needs reference to GameManager (export NodePath or find_child)

## Edge Cases & Considerations

1. **Double ESC Prevention:** Don't allow ESC spam - wait for fade animation to complete
2. **Game Over State:** Disable ESC menu when eagle dies (check GameManager.is_game_over)
3. **Scene Transitions:** Hide menu before scene changes
4. **Audio:** Keep wind/music playing during pause (atmospheric continuity)
5. **Button Focus:** No auto-focus on buttons (mouse-only interaction)

## Balancing Parameters

### Tweakable Values (Export Variables)
```gdscript
@export var fade_duration: float = 0.2  # Fade in/out speed
@export var overlay_opacity: float = 0.7  # Max overlay darkness (0.0-1.0)
@export var overlay_color: Color = Color(0.06, 0, 0.07, 1.0)  # Base overlay color
```

## Prompt for Coding Agent

**High-Level Task:**
Create a pause menu system that freezes the game when ESC is pressed, displays a menu with Resume/Restart/Quit buttons over a dimmed overlay, and allows the player to toggle pause or take actions.

**Implementation Decisions:**
1. Use `ColorRect` with tweened alpha for fade overlay (simpler than texture)
2. Use Godot's built-in pause system (`get_tree().paused`)
3. Set ESC menu to `PROCESS_MODE_ALWAYS` so it works during pause
4. Use Tween for smooth fade in/out animations (0.2s duration)
5. ESC key toggles menu on/off for quick resume
6. Resume button = same as ESC toggle
7. Restart button = calls `GameManager.restart_game()`
8. Quit button = `get_tree().quit()`
9. Prevent input spam with animation state tracking
10. Hide menu initially, show only when ESC pressed

**Key Technical Points - UiEscMenu Script:**
- Script class name: `UiEscMenu`
- Extends: `Node2D`
- Export NodePaths for FadeOverlay, buttons, and GameManager reference
- Use `_input()` for ESC key detection (works during pause)
- Track animation state to prevent double-toggle
- Connect button signals in `_ready()`
- Clean up tweens properly on hide
- Find GameManager reference (export NodePath or auto-find)

**Key Technical Points - GameManager.restart_game():**
- Public function that can be called from anywhere
- Step 1: Unpause game (`get_tree().paused = false`)
- Step 2: Reset is_game_over flag to false
- Step 3: Reset GameStats if singleton exists
- Step 4: Reset StageManager to stage 1 if singleton exists
- Step 5: Call SceneManager.reload_current_scene() or fallback to get_tree().reload_current_scene()
- Add this function to existing GameManager script (don't create new file)
