# Debug Keyboard Actions & Testing Controls

This document lists all available debug keyboard shortcuts and testing methods for the Eagle game development.

## Normal Gameplay Controls

For reference, the normal gameplay controls are:
- **`W`**: Flap wings (move up)
- **`S`**: Dive (move down)
- **`E`**: Eat fish
- **`Space`**: Drop fish (at nest)
- **`H`**: Screech

---

## Eagle Debug Controls

These debug controls are implemented in the **Eagle** script (`scripts/eagle.gd`):

### **`F` Key**: Add Fish to Eagle
- **Purpose**: Instantly adds a fish to the eagle's talons (as if caught)
- **Behavior**:
  - Will not work if eagle is already carrying a fish or dying
  - Creates and attaches a fish instance directly to the eagle
  - Fish appears in proper caught state with collision disabled
  - Fish scale is adjusted to match "caught" size
  - Emits `fish_caught_changed` signal for animation updates
- **Console Output**: `🔧 DEBUG: Fish added to eagle`
- **Implementation**: `scripts/eagle.gd:625-664`

### **`N` Key**: Spawn Nest on Next Obstacle
- **Purpose**: Forces the next obstacle to spawn with a nest
- **Behavior**:
  - Sets the nest spawner to trigger on the very next obstacle that can carry a nest
  - Useful for testing nest feeding mechanics without waiting
  - Requires nests to be enabled in the current stage
  - Manipulates the nest spawner's internal counter
- **Console Output**: `🔧 DEBUG: Next obstacle will have a nest`
- **Implementation**: `scripts/eagle.gd:666-678`

### **`M` Key**: Decrease Energy Capacity
- **Purpose**: Tests the morale/energy capacity system
- **Behavior**:
  - Decreases energy capacity by 15 points
  - Shows diagonal pattern effect on energy bar
  - Tests energy capacity loss mechanics (same as missing a nest)
- **Implementation**: `scripts/eagle.gd:172-174`

### **`K` Key**: Trigger Dying State
- **Purpose**: Tests game over flow and death mechanics
- **Behavior**:
  - Forces eagle energy to 0 and enters dying animation
  - Eagle falls with dying animation
  - Triggers game over sequence
- **Console Output**: `🔧 DEBUG: Manually triggering dying state`
- **Implementation**: `scripts/eagle.gd:176-180`

---

## General Testing Tips

- **`P` Key**: Quickly advance to the next stage to test different configurations
- **Stage Navigation (`1`–`6`)**: Jump directly to a specific stage (see detailed list below)
- **`Ctrl + R`**: Reset and start testing from the beginning
- **`Enter` Key**: Force obstacle spawns to test nest mechanics quickly
- **`I` Key**: Test Single Text mode ("Nest ahead!" in cyan)
- **`U` Key**: Test Double Text mode ("Nest missed" + "-Morale")
- **`O` Key**: Test Text + Icon mode ("+20" with energy icon)
- **`R` Key**: Restart game

---

## Usage Notes

- Debug controls are designed for testing and balancing gameplay mechanics
- All debug actions print confirmation messages to the console
- Debug controls respect game state (e.g., can't add fish while dying)
- Debug keys use raw keycodes and are not remappable (by design)




## Stage System Debug Controls

These controls are handled by the **GameManager** and allow testing of the stage progression system:

---

## 🔧 DEBUG CONTROLS STATUS: COMMENTED OUT

**All debug controls have been commented out for production builds.**

### How to Re-enable Debug Controls

To re-enable debug controls for testing and development:

#### 1. Eagle Debug Controls (`scripts/eagle.gd`)
- **Location**: Lines 168-188 and 632-687
- **Action**: Uncomment the `_unhandled_input(event)` function and the debug methods section
- **Controls**: F, N, M, K keys for fish, nest, energy, and death testing

#### 2. Game Manager Debug Controls (`scripts/game_manager.gd`)
- **Location**: Lines 123-150
- **Action**: Uncomment the `_input(event)` function
- **Controls**: P, R, 1-6, A, F12 keys for stage navigation and FPS counter

#### 3. UI Message Debug Controls (`scripts/ui/ui_message.gd`)
- **Location**: Lines 378-413
- **Action**: Uncomment the `_unhandled_input(event)` function
- **Controls**: I, U, O keys for testing different UI message modes

### Quick Re-enable Instructions

1. **Search for**: `# DEBUG CONTROLS COMMENTED OUT`
2. **Replace with**: `func _unhandled_input(event):` (or `func _input(event):` for game_manager.gd)
3. **Remove the `#` comment markers** from the debug function implementations
4. **Test the controls** to ensure they work properly

### Debug Control Locations Summary

| Script | Function | Lines | Controls |
|--------|----------|-------|----------|
| `scripts/eagle.gd` | `_unhandled_input()` | 168-188 | F, N, M, K |
| `scripts/eagle.gd` | Debug methods | 632-687 | debug_add_fish(), debug_spawn_nest_on_next_obstacle() |
| `scripts/game_manager.gd` | `_input()` | 123-150 | P, R, 1-6, A, F12 |
| `scripts/ui/ui_message.gd` | `_unhandled_input()` | 378-413 | I, U, O |

**Note**: The Enter key debug control mentioned in the documentation appears to not be implemented yet.

