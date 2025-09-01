# Stage-Based Balancing System Design

## Overview

This document outlines the design for a comprehensive stage-based balancing system for the Eagle game. The system will control difficulty progression through predefined stages and then transition to an automatic difficulty scaling mechanism.

## Current System Analysis

### Existing Spawners
1. **ObstacleSpawner**: Manages mountains, stalactites, floating islands with weights and timing
2. **FishSpawner**: Controls fish spawning with boost system before nests
3. **NestSpawner**: Handles nest placement on obstacles with skip intervals

### Current Parameters (to be stage-controlled)
- World/eagle movement speed (`obstacle_movement_speed`)
- Obstacle type weights (`mountain_weight`, `stalactite_weight`, `floating_island_weight`)
- Spawn intervals and timing variance
- Fish spawn intervals and boost parameters
- Nest skip intervals (`min_skipped_obstacles`, `max_skipped_obstacles`)

## Core Components

### 1. StageManager (Singleton)
**Purpose**: Central controller for stage progression and parameter management
**Responsibilities**:
- Track current stage
- Apply stage-specific parameters to all spawners
- Monitor stage completion conditions
- Trigger stage transitions
- Manage automatic difficulty progression

```gdscript
# Example structure
class_name StageManager
extends Node

var current_stage: int = 1
var current_stage_config: StageConfiguration
var stage_timer: float = 0.0
var stage_nest_count: int = 0
var auto_difficulty_enabled: bool = false

signal stage_changed(new_stage: int)
signal auto_difficulty_started()
```

### 2. StageConfiguration (Resource)
**Purpose**: Data container for stage-specific parameters
**File Format**: `.tres` resource files for easy editing in Godot editor

```gdscript
class_name StageConfiguration
extends Resource

# Stage Identity
@export var stage_number: int = 1
@export var stage_name: String = "Tutorial Stage"

# World Parameters
@export var world_speed: float = 300.0

# Obstacle Parameters
@export var mountain_weight: int = 10
@export var stalactite_weight: int = 0  # 0 = disabled
@export var floating_island_weight: int = 5

# Obstacle Positioning Parameters
# Mountains and Stalactites use height ranges
# Floating Islands use offset parameters from screen edges

# Obstacle Distance Parameters
@export var min_obstacle_distance: float = 400.0
@export var max_obstacle_distance: float = 800.0
@export var same_obstacle_repeat_chance: float = 0.1  # 10% chance

# Fish Parameters
@export var fish_enabled: bool = false
@export var fish_min_spawn_interval: float = 3.0
@export var fish_max_spawn_interval: float = 7.0

# Nest Parameters
@export var nests_enabled: bool = false
@export var nest_min_skipped_obstacles: int = 3
@export var nest_max_skipped_obstacles: int = 6

# Stage Completion Condition
@export var completion_type: CompletionType = CompletionType.TIMER
@export var completion_value: float = 10.0  # 10 seconds or 10 nests

enum CompletionType {
    TIMER,      # Complete after X seconds
    NESTS       # Complete after X nests spawned
}
```

### 3. AutoDifficultySystem
**Purpose**: Gradually increase difficulty after manual stages complete
**Parameters**: Percentage-based modifiers for smooth progression

```gdscript
class_name AutoDifficultySystem
extends RefCounted

# Progression intervals
@export var progression_interval: float = 30.0  # Every 30 seconds

# Speed progression
@export var speed_increase_rate: float = 0.05  # 5% increase per interval
@export var max_speed_multiplier: float = 2.0  # Cap at 2x original speed

# Spawn rate progression
@export var spawn_rate_increase: float = 0.1   # 10% faster spawning
@export var min_spawn_interval_cap: float = 1.0  # Never faster than 1 second

# Obstacle weight progression
@export var stalactite_weight_increase: int = 1  # Add 1 weight per interval
@export var max_stalactite_weight: int = 20     # Cap stalactite frequency

# Distance progression
@export var distance_decrease_rate: float = 0.05  # 5% closer obstacles
@export var min_distance_cap: float = 200.0       # Minimum safe distance

# Nest progression
@export var nest_interval_decrease: int = 1      # More frequent nests
@export var min_nest_interval: int = 2           # Minimum obstacles between nests
```

## Stage Definitions

### Stage 1: Introduction (10 seconds)
- **Purpose**: Familiarize player with basic movement and obstacle avoidance
- **Obstacles**: Mountains + Islands only
- **Fish**: Disabled
- **Nests**: Disabled
- **Speed**: Slow (250)
- **Completion**: Timer (10 seconds)

### Stage 2: Fish Introduction (5 seconds)
- **Purpose**: Introduce fish mechanics
- **Obstacles**: Mountains + Islands
- **Fish**: Enabled (generous spawn rate)
- **Nests**: Disabled
- **Speed**: Same as Stage 1
- **Completion**: Timer (5 seconds)

### Stage 3: Nest Introduction (Until 2 nests)
- **Purpose**: Introduce nest feeding mechanics
- **Obstacles**: Mountains + Islands
- **Fish**: Enabled
- **Nests**: Enabled (frequent)
- **Speed**: Slightly increased (275)
- **Completion**: 2 nests spawned

### Stage 4: Stalactite Introduction (Until 3 nests)
- **Purpose**: Add stalactites, increase challenge
- **Obstacles**: Mountains + Islands + Stalactites
- **Fish**: Enabled
- **Nests**: Enabled
- **Speed**: Increased (300)
- **Changes**: Higher mountains, closer obstacles
- **Completion**: 3 nests spawned

### Stage 5: Increased Difficulty (Until 5 nests)
- **Purpose**: Ramp up all parameters
- **Obstacles**: All types with balanced weights
- **Fish**: Faster spawning
- **Nests**: Less frequent
- **Speed**: Higher (350)
- **Completion**: 5 nests spawned

### Stage 6: Transition to Auto (Until 10 nests)
- **Purpose**: Final manual stage before auto-difficulty
- **Obstacles**: All types, high difficulty
- **Fish**: High difficulty settings
- **Nests**: Challenging intervals
- **Speed**: High (400)
- **Completion**: 10 nests spawned → Enable auto-difficulty

## Implementation Architecture

### Legacy Systems to Remove
As part of the clean refactor, these existing systems will be completely removed:

**ObstacleSpawner:**
- All @export difficulty parameters (`difficulty_increase_interval`, `difficulty_spawn_rate_multiplier`, etc.)
- `increase_difficulty()` method and automatic difficulty timer
- Hardcoded spawn weights and intervals

**FishSpawner:**
- All @export spawn parameters (`spawn_interval`, `spawn_interval_variance`, etc.)
- `increase_difficulty()` method
- Pre-nest boost system parameters (will be integrated into stage configs)

**NestSpawner:**
- All @export difficulty parameters (`nest_difficulty_increase_interval`, etc.)
- `_increase_nest_difficulty()` method and automatic progression
- Hardcoded min/max skipped obstacles

### Phase 1: Core System
1. Create `StageManager` singleton
2. Create `StageConfiguration` resource class
3. Create 6 stage configuration files (.tres)
4. Implement stage progression logic

### Phase 2: Clean Spawner Refactoring
1. **Complete refactor** of `ObstacleSpawner` - remove all hardcoded @export parameters
2. **Complete refactor** of `FishSpawner` - remove all hardcoded @export parameters  
3. **Complete refactor** of `NestSpawner` - remove all hardcoded @export parameters
4. Remove old difficulty progression systems from all spawners
5. Implement clean `apply_stage_config()` method in each spawner

### Phase 3: Auto-Difficulty System
1. Create `AutoDifficultySystem` class
2. Implement percentage-based parameter modification
3. Add progression timers and caps
4. Integrate with existing difficulty systems

### Phase 4: UI Integration
1. Add stage notification system
2. Create stage progress indicators
3. Add debug tools for stage testing
4. Implement balancing tweaks interface

## Spawner Refactoring Plan

### ObstacleSpawner Changes
```gdscript
# Complete refactor - remove all hardcoded @export parameters
# All parameters now come from StageConfiguration

func apply_stage_config(config: StageConfiguration):
    obstacle_movement_speed = config.world_speed
    mountain_weight = config.mountain_weight
    stalactite_weight = config.stalactite_weight
    floating_island_weight = config.floating_island_weight
    
    # Calculate spawn intervals from distance parameters
    var distance_range = config.max_obstacle_distance - config.min_obstacle_distance
    spawn_interval = config.min_obstacle_distance / config.world_speed
    spawn_interval_variance = distance_range / config.world_speed / 2
    min_spawn_interval = config.min_obstacle_distance / config.world_speed
    
    _setup_obstacle_types()  # Refresh obstacle weights
    
    # Remove old difficulty progression system - replaced by stage system
```

### FishSpawner Changes
```gdscript
# Complete refactor - remove all hardcoded @export parameters
# Fish spawning entirely controlled by stage configuration

func apply_stage_config(config: StageConfiguration):
    if not config.fish_enabled:
        spawn_timer.stop()
        return
    
    spawn_interval = config.fish_max_spawn_interval
    min_spawn_interval = config.fish_min_spawn_interval
    spawn_interval_variance = (config.fish_max_spawn_interval - config.fish_min_spawn_interval) / 2
    
    # Remove boost system parameters - integrate into stage configs instead
    # Each stage can define its own fish spawn behavior
    
    spawn_timer.start()
```

### NestSpawner Changes
```gdscript
# Complete refactor - remove all hardcoded @export parameters and old difficulty system
# Nest spawning entirely controlled by stage configuration

func apply_stage_config(config: StageConfiguration):
    if not config.nests_enabled:
        # Disable nest spawning cleanly
        min_skipped_obstacles = 999
        max_skipped_obstacles = 999
        return
    
    min_skipped_obstacles = config.nest_min_skipped_obstacles
    max_skipped_obstacles = config.nest_max_skipped_obstacles
    _set_next_nest_spawn_target()  # Recalculate with new values
    
    # Remove old automatic difficulty increase system - replaced by stage/auto-difficulty
```

## Stage Configuration Files Structure

```
scenes/configs/stages/
├── stage_01_introduction.tres
├── stage_02_fish_intro.tres
├── stage_03_nest_intro.tres
├── stage_04_stalactites.tres
├── stage_05_harder.tres
└── stage_06_final.tres
```

## Auto-Difficulty Integration

After Stage 6 completion:
1. StageManager enables auto-difficulty mode
2. AutoDifficultySystem takes over parameter control
3. Base values from Stage 6 are used as starting point
4. Progressive percentage-based increases applied
5. All changes capped to prevent impossible difficulty

## Benefits of This System

### For Developers
- **Modularity**: Each stage isolated in resource files
- **Tweakability**: Easy to adjust parameters without code changes
- **Expandability**: Simple to add new stages or parameters
- **Testing**: Can jump to any stage for testing

### For Players
- **Progressive Learning**: Each stage introduces one new concept
- **Smooth Transitions**: No sudden difficulty spikes
- **Consistent Challenge**: Auto-difficulty maintains engagement
- **Feedback**: Clear stage progression indicators

### For Game Design
- **Data-Driven**: Parameters in easily editable files
- **Balanced**: Systematic approach to difficulty curves
- **Flexible**: Can be tuned based on player feedback
- **Scalable**: Auto-system ensures long-term engagement

## Technical Notes

### Memory Efficiency
- Stage configurations loaded on-demand
- Only current stage data kept in memory
- Auto-difficulty calculations lightweight

### Performance Considerations
- Stage transitions happen at safe moments (not during gameplay-critical sections)
- Parameter applications batched to avoid frame stutters
- Minimal overhead for stage parameter lookups

### Debug Tools
- Console commands for stage switching
- Parameter override system for testing
- Stage progression visualization
- Performance monitoring for parameter changes

## Future Expansions

### Additional Parameters
- Enemy spawn rates and types
- Weather/environmental effects
- Special obstacle behaviors
- Power-up spawn rates

### Advanced Features
- Player-specific difficulty adaptation
- Multiple difficulty tracks
- Achievement-based stage unlocks
- Custom stage creation tools

---

This design provides a comprehensive, flexible, and maintainable system for controlling game difficulty through both predefined stages and automatic progression, ensuring a smooth and engaging player experience throughout the entire game.
