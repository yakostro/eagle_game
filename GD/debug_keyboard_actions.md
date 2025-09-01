# Debug Keyboard Actions & Testing Controls

This document lists all available debug keyboard shortcuts and testing methods for the Eagle game development.

## Stage System Debug Controls

These controls are handled by the **GameManager** and allow testing of the stage progression system:

### Stage Progression
- **`P` Key**: Force advance to the next stage immediately
  - Bypasses current stage timer/nest requirements
  - Useful for quickly testing stage transitions
  - Console output: `🧪 Manual stage advance triggered!`

### Stage Navigation
- **`1` Key**: Skip directly to Stage 1 (Introduction)
- **`2` Key**: Skip directly to Stage 2 (Fish Introduction) 
- **`3` Key**: Skip directly to Stage 3 (Nest Introduction)
- **`4` Key**: Skip directly to Stage 4 (Stalactites)
- **`5` Key**: Skip directly to Stage 5 (Harder)
- **`6` Key**: Skip directly to Stage 6 (Final)
- Console output: `🧪 Skipping to stage X!`

### Stage Reset
- **`Ctrl + R`**: Reset stage progress back to Stage 1
  - Resets stage timer and nest counters
  - Restarts the entire stage progression
  - Console output: `🧪 Reset stage progress triggered!`

## Spawner Debug Controls

### Manual Obstacle Spawning
- **`Enter` Key** (`ui_accept`): Manually spawn a random obstacle
  - Handled by **ObstacleSpawner**
  - Bypasses normal spawn timer
  - Uses current stage configuration for obstacle selection
  - Console output: `🎮 Manual obstacle spawn triggered!`

## Stage System Verification

The game automatically runs comprehensive stage system tests on startup, which display in the console:

### Automatic Testing (Console Output)
- **Task 8 Verification**: Obstacle spawner refactor status
- **Task 9 Verification**: Obstacle spawner stage integration
- **Task 10 Verification**: Fish spawner stage integration  
- **Task 11 Verification**: Nest spawner stage integration
- **Stage loading tests**: All 6 stage configurations
- **Parameter progression tests**: Speed increases, stalactite visibility, etc.

### Stage Progression Monitoring
The console shows detailed information when stages change:
```
✨ Successfully advanced to Stage 2: Fish Introduction
🏔️  ObstacleSpawner: Updating to Stage 2
🐟 FishSpawner: Updating to Stage 2
🏠 NestSpawner: Updating to Stage 2
```

## In-Game HUD

### Enhanced Stage HUD
- **Top-left corner**: Shows comprehensive game information in three lines:
  - **Line 1**: Game timer in MM:SS format: `Time: 02:34`
  - **Line 2**: Current stage with completion info
    - Timer stages: `Stage 1: Introduction (8.5s)`
    - Nest stages: `Stage 3: Nest Intro (1 left)`
  - **Line 3**: Nest statistics: `Nests: 3 fed / 5 spawned`
    - **Fed**: Number of nests successfully fed by the eagle
    - **Spawned**: Total number of nests created in the game

## Development Testing Methods

### Fish Spawner Testing
Available via script calls (not keyboard shortcuts):
- `fish_spawner.spawn_fish_now()`: Manually spawn a fish
- `fish_spawner.test_boost_system()`: Test pre-nest fish boost system

### Nest Spawner Testing
The nest spawner provides detailed console output for debugging:
- Shows obstacle processing: `🏠 Nest spawner processed Mountain | Since last nest: 2/4`
- Shows nest spawn decisions: `✅ Mountain will get a nest!` / `❌ Island cannot carry nests`
- Shows nest spawn confirmations: `🏠 Nest spawned! Total nests: 3`

### Stage Configuration Testing
Each spawner provides detailed output when stage configs are applied:
```
🏔️  Stage config applied:
   - World speed: 275
   - Mountain weight: 5
   - Stalactite weight: 2
   - Island weight: 5

🐟 Stage config applied:
   - Fish enabled: true
   - Spawn interval: 2.0±1.5s

🏠 Stage config applied:
   - Nests enabled: true
   - Min skipped obstacles: 3
   - Max skipped obstacles: 6
```

## Regular Game Controls (Non-Debug)

For reference, the normal gameplay controls are:
- **`W`**: Flap wings (move up)
- **`S`**: Dive (move down) 
- **`E`**: Eat fish
- **`Space`**: Drop fish (at nest)
- **`H`**: Screech

---

## Tips for Testing

1. **Use `P` key** to quickly advance through stages to test different configurations
2. **Use number keys (1-6)** to jump directly to a specific stage you want to test
3. **Use `Ctrl+R`** to reset and start testing from the beginning
4. **Use `Enter`** to force obstacle spawns if you want to test nest mechanics quickly
5. **Watch the console** for detailed stage progression and parameter information
6. **Check the stage HUD** in the top-left corner to confirm stage changes

## Stage Behavior Reference

- **Stage 1**: Mountains + Islands only, no fish, no nests (10s timer)
- **Stage 2**: Mountains + Islands, fish enabled, no nests (5s timer) 
- **Stage 3**: Mountains + Islands, fish + nests enabled (2 nests to advance)
- **Stage 4**: All obstacles including stalactites (3 nests to advance)
- **Stage 5**: Higher difficulty parameters (5 nests to advance)
- **Stage 6**: Maximum difficulty, auto-system starts (10 nests to advance)

---

**All debug controls are automatically available in development builds. No additional setup required.**
