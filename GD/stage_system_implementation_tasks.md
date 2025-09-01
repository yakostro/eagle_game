# Stage Balancing System - Implementation Tasks

## Overview
These are small, focused tasks for implementing the stage-based balancing system. Each task builds upon the previous ones and can be tested independently.

---

## **TASK 1: Create StageConfiguration Resource Class**

### Goal
Create the basic data structure for stage parameters.

### What to Build
- Create `scripts/systems/stage_configuration.gd`
- Implement all stage parameters as @export variables
- Add enum for completion types

### Expected Result
- Can create .tres files with stage data in Godot editor
- All parameters visible and editable in inspector

### Testing
- Create the script and verify it shows up in "Create Resource" dialog
- Create a test .tres file and verify all parameters are editable

### Files to Create
- `scripts/systems/stage_configuration.gd`

---

## **TASK 2: Create Basic StageManager Singleton**

### Goal
Create the central stage management system without any logic yet.

### What to Build
- Create `scripts/systems/stage_manager.gd`
- Add it as AutoLoad singleton in project settings
- Basic structure: current stage tracking, signals, placeholder methods

### Expected Result
- StageManager accessible globally via `StageManager.current_stage`
- Basic debug output shows it's working

### Testing
- Add debug print in game scene to show StageManager is loaded
- Verify singleton is accessible from any script

### Files to Create
- `scripts/systems/stage_manager.gd`

### Files to Modify
- `project.godot` (AutoLoad section)

---

## **TASK 3: Create First Stage Configuration**

### Goal
Create one working stage configuration file for testing.

### What to Build
- Create `scenes/configs/stages/` folder
- Create `stage_01_introduction.tres` with Stage 1 parameters
- Use values from design document

### Expected Result
- Stage 1 config file exists and is editable
- All parameters have sensible values for first stage

### Testing
- Open .tres file in inspector and verify all values
- Load the resource in a test script and print values

### Files to Create
- `scenes/configs/stages/stage_01_introduction.tres`

---

## **TASK 4: Add Stage Loading to StageManager**

### Goal
Make StageManager capable of loading and applying stage configurations.

### What to Build
- Add `load_stage(stage_number: int)` method
- Add `current_stage_config` property
- Add file path logic to find stage files
- Add error handling for missing stages

### Expected Result
- Can call `StageManager.load_stage(1)` and it loads stage 1 config
- Debug output shows loaded parameters

### Testing
- Call `load_stage(1)` from game scene _ready()
- Print loaded config values to verify they match the .tres file

### Files to Modify
- `scripts/systems/stage_manager.gd`

---

## **TASK 5: Add Stage Progression Logic**

### Goal
Add the ability to track stage completion and advance stages.

### What to Build
- Add timer tracking for time-based stages
- Add nest count tracking for nest-based stages
- Add `check_stage_completion()` method
- Add `advance_to_next_stage()` method
- Add stage_changed signal

### Expected Result
- Stage 1 automatically advances to Stage 2 after 10 seconds
- Debug output shows stage progression happening

### Testing
- Start game, wait 10 seconds, verify stage advances to 2
- Add temporary "skip stage" button for testing

### Files to Modify
- `scripts/systems/stage_manager.gd`

---

## **TASK 6: Create All Stage Configuration Files**

### Goal
Create all 6 stage configuration files with proper values.

### What to Build
- `stage_02_fish_intro.tres` through `stage_06_final.tres`
- Use parameter values from design document
- Ensure progression makes sense

### Expected Result
- All 6 stage files exist with different parameter values
- Each stage is harder than the previous one

### Testing
- Load each stage in StageManager and verify parameters are different
- Check that progression looks reasonable

### Files to Create
- `scenes/configs/stages/stage_02_fish_intro.tres`
- `scenes/configs/stages/stage_03_nest_intro.tres`
- `scenes/configs/stages/stage_04_stalactites.tres`
- `scenes/configs/stages/stage_05_harder.tres`
- `scenes/configs/stages/stage_06_final.tres`

---

## **TASK 7: Test Core Stage System**

### Goal
Verify the core stage system works end-to-end before touching spawners.

### What to Build
- Add debug UI to show current stage and parameters
- Add manual stage skip button for testing

### Files to Modify
- Add temporary debug UI to game scene

---

## **TASK 8: Refactor ObstacleSpawner - Part 1 (Remove Old System)**

### Goal
Clean out old difficulty system from ObstacleSpawner.

### What to Build
- Remove all @export difficulty parameters
- Remove `increase_difficulty()` method
- Remove difficulty timer logic
- Keep spawning functionality working with current values

### Expected Result
- ObstacleSpawner still spawns obstacles normally
- No more automatic difficulty increases
- Code is cleaner

### Testing
- Run game and verify obstacles still spawn
- Verify no console errors about missing methods/properties

### Files to Modify
- `scripts/spawners/obstacle_spawner.gd`

---

## **TASK 9: Refactor ObstacleSpawner - Part 2 (Add Stage Integration)**

### Goal
Make ObstacleSpawner use stage configurations.

### What to Build
- Add `apply_stage_config(config: StageConfiguration)` method
- Connect to StageManager.stage_changed signal
- Apply stage parameters to spawning behavior
- Remove hardcoded @export parameters

### Expected Result
- Obstacle spawning changes based on current stage
- World speed, weights, and intervals update per stage

### Testing
- Verify obstacles spawn faster in later stages
- Verify stalactites only appear in stage 4+
- Check that obstacle types change based on weights

### Files to Modify
- `scripts/spawners/obstacle_spawner.gd`

---

## **TASK 10: Refactor FishSpawner**

### Goal
Make FishSpawner use stage configurations.

### What to Build
- Remove all @export spawn parameters
- Add `apply_stage_config(config: StageConfiguration)` method
- Connect to StageManager.stage_changed signal
- Handle fish enabled/disabled based on stage

### Expected Result
- Fish only spawn when enabled in stage config
- Fish spawn rates change per stage
- No fish in stage 1, fish appear in stage 2+

### Testing
- Verify no fish in stage 1
- Verify fish appear starting in stage 2
- Check fish spawn rates change between stages

### Files to Modify
- `scripts/spawners/fish_spawner.gd`

---

## **TASK 11: Refactor NestSpawner**

### Goal
Make NestSpawner use stage configurations.

### What to Build
- Remove old difficulty system
- Add `apply_stage_config(config: StageConfiguration)` method
- Connect to StageManager.stage_changed signal
- Handle nest enabled/disabled based on stage
- Update stage completion tracking

### Expected Result
- Nests only spawn when enabled in stage config
- No nests in stages 1-2, nests appear in stage 3+
- Stage completion works for nest-based stages

### Testing
- Verify no nests in stages 1-2
- Verify nests appear in stage 3
- Check that nest-based stage completion works

### Files to Modify
- `scripts/spawners/nest_spawner.gd`
- `scripts/systems/stage_manager.gd` (for nest count tracking)

---

## **TASK 12: Test Complete Spawner Integration**

### Goal
Verify all spawners work together with stage system.

### What to Build
- Play through all 6 stages
- Verify each spawner responds to stage changes
- Fix any integration issues

### Expected Result
- Smooth progression through all stages
- All mechanics appear at the right time
- No console errors or weird behavior

### Testing
- Full playthrough of stages 1-6
- Verify timing and difficulty progression feels right
- Test edge cases (fast stage skipping, etc.)

---

## **TASK 13: Create AutoDifficultySystem Class**

### Goal
Create the automatic difficulty progression system.

### What to Build
- Create `scripts/systems/auto_difficulty_system.gd`
- Implement percentage-based parameter modification
- Add progression timers and safety caps
- Keep it separate from StageManager initially

### Expected Result
- AutoDifficultySystem can modify stage parameters over time
- All increases have proper caps
- System is ready to integrate

### Testing
- Create test script that applies auto-difficulty to stage 6 config
- Verify parameters increase gradually
- Check that caps prevent impossible values

### Files to Create
- `scripts/systems/auto_difficulty_system.gd`

---

## **TASK 14: Integrate AutoDifficultySystem**

### Goal
Connect auto-difficulty to stage system after stage 6.

### What to Build
- Enable auto-difficulty when stage 6 completes
- Apply auto-difficulty modifications to spawners
- Add auto-difficulty status to debug UI

### Expected Result
- After stage 6, difficulty continues to increase automatically
- Parameters smoothly scale up over time
- Game becomes progressively harder

### Testing
- Reach stage 6 and verify auto-difficulty activates
- Play for several minutes and verify difficulty increases
- Check that caps prevent impossible gameplay

### Files to Modify
- `scripts/systems/stage_manager.gd`
- All spawner scripts (for auto-difficulty integration)

---

## **TASK 15: Polish and Debug UI**

### Goal
Add final polish and proper debug tools.

### What to Build
- Clean debug UI showing current stage and parameters
- Console commands for stage testing
- Parameter monitoring for balancing
- Remove temporary debug code

### Expected Result
- Clean, professional debug interface
- Easy tools for testing and balancing
- System ready for final balancing passes

### Testing
- Test all debug features
- Verify system is stable and performant
- Do final playthrough for balancing feedback

---

## Task Dependencies

```
1 → 2 → 3 → 4 → 5 → 6 → 7
                ↓
8 → 9 → 10 → 11 → 12 → 13 → 14 → 15
```

## Notes for Developer Agent

- Each task should be completed and tested before moving to the next
- If a task reveals issues with previous tasks, fix them before proceeding
- Add plenty of debug output during implementation for easier testing
- Follow Godot 4.2 best practices and the project's naming conventions
- Remember: node names use camelCase, script files use snake_case
