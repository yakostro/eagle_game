# Predictive Nest Spawning System Design

## High-Level Concept

Transform the current reactive nest spawning system into a predictive system that can forecast nest locations 3-4 seconds before they appear, enabling proper early warning indicators for better player reaction time.

## Current Problem

The offscreen nest indicator appears too late because:
- Nests are decided at the moment obstacles spawn
- No lookahead system exists to predict future nest placements
- Player needs 3-4 seconds advance warning for proper reaction

## Architectural Solution: Spawn Prediction Pipeline

### 1. Core Architecture: Two-Phase Spawning

**Phase 1: Prediction Phase**
- Pre-calculate upcoming obstacles and their properties
- Determine which future obstacles will receive nests
- Generate "nest predictions" with timing and positioning data

**Phase 2: Execution Phase** 
- Spawn obstacles according to pre-calculated plan
- Apply nests to obstacles that were pre-determined to carry them
- Trigger early warning indicators based on predictions

### 2. Key Components

#### SpawnPredictor (New Component)
- **Purpose**: Forecasts upcoming spawns based on current game state
- **Responsibilities**:
  - Calculate future obstacle spawn timings and types
  - Determine which obstacles will carry nests
  - Generate prediction events for early warning systems
  - Maintain a "spawn timeline" buffer

#### PredictiveObstacleSpawner (Enhanced)
- **Purpose**: Execute pre-calculated spawn plans
- **Responsibilities**:
  - Follow the SpawnPredictor's timeline
  - Spawn obstacles according to predicted schedule
  - Apply nests to pre-determined obstacles

#### EarlyWarningSystem (New Component)
- **Purpose**: Handle early indicators and warnings
- **Responsibilities**:
  - Listen to nest predictions from SpawnPredictor
  - Trigger offscreen indicators 3-4 seconds early
  - Coordinate multiple types of warnings (visual, audio, etc.)

### 3. Prediction Algorithm Design

#### Prediction Window
- **Lookahead Distance**: Calculate spawns for next 1200-1600 pixels (3-4 seconds at 400px/s)
- **Prediction Refresh**: Recalculate predictions every 0.5-1.0 seconds or when parameters change
- **Buffer Maintenance**: Keep predictions synchronized with actual world state

#### Nest Prediction Logic
```
For each predicted obstacle in lookahead window:
1. Apply current nest spawning rules (obstacle count, type compatibility)
2. Calculate nest probability based on stage configuration
3. If nest predicted: store {obstacle_id, spawn_time, world_position, nest_position}
4. Generate early warning event with 3-4 second lead time
```

#### World Position Calculation
- **Spawn Position Prediction**: Calculate exact world coordinates where obstacles will appear
- **Nest Position Prediction**: Calculate final nest world position including placeholder selection
- **Camera Projection**: Project future world positions to screen coordinates for indicator placement

### 4. Implementation Strategy

#### Stage 1: Core Prediction Framework
- Create SpawnPredictor component
- Implement basic obstacle spawn timeline prediction
- Add prediction data structures and events

#### Stage 2: Nest Prediction Integration
- Extend SpawnPredictor to handle nest prediction logic
- Modify NestSpawner to work with predictions
- Implement nest prediction validation

#### Stage 3: Early Warning System
- Create EarlyWarningSystem component
- Enhance UIOffscreenNestIndicator to use predictions
- Add configurable warning lead times

#### Stage 4: Synchronization & Polish
- Ensure predictions stay synchronized with actual spawns
- Add prediction accuracy validation
- Optimize prediction performance

### 5. Scene Architecture Changes

#### New Node Structure
```
Game Scene
├── Spawners
│   ├── SpawnPredictor (new)
│   ├── ObstacleSpawner (enhanced)
│   ├── NestSpawner (modified)
│   └── EarlyWarningSystem (new)
└── UI
    └── UIOffscreenNestIndicator (enhanced)
```

#### Signal Flow
```
SpawnPredictor → nest_predicted(prediction_data) → EarlyWarningSystem
EarlyWarningSystem → show_early_warning(position, time) → UIOffscreenNestIndicator
SpawnPredictor → obstacle_spawn_planned(obstacle_data) → ObstacleSpawner
ObstacleSpawner → execute_spawn(obstacle) → NestSpawner (if nest pre-determined)
```

### 6. Data Structures

#### SpawnPrediction
```gdscript
class_name SpawnPrediction
var obstacle_type: String
var spawn_time: float           # Game time when spawn occurs
var world_position: Vector2     # World coordinates of spawn
var will_have_nest: bool        # Whether this obstacle gets a nest
var nest_position: Vector2      # Local position of nest on obstacle (if applicable)
var nest_world_position: Vector2 # Calculated world position of nest
```

#### PredictionTimeline
```gdscript
class_name PredictionTimeline
var predictions: Array[SpawnPrediction] = []
var prediction_horizon: float = 4.0  # Seconds to predict ahead
var last_update_time: float = 0.0
```

### 7. Configuration Parameters

#### Prediction Settings
- `prediction_lookahead_time: float = 4.0` # Seconds to predict ahead
- `prediction_refresh_interval: float = 0.5` # How often to recalculate
- `early_warning_lead_time: float = 3.5` # When to show indicators
- `prediction_accuracy_buffer: float = 0.2` # Tolerance for timing variations

#### Warning System Settings
- `warning_fade_in_time: float = 0.3` # Indicator appearance animation
- `warning_position_smoothing: bool = true` # Smooth indicator movement
- `multiple_warning_spacing: float = 100.0` # Minimum distance between indicators

## Implementation Prompt for Coding Agent

**High-Level Task**: Implement a predictive spawning system that forecasts nest placements 3-4 seconds in advance to enable proper early warning indicators.

**Implementation Decision**: Create a two-phase spawning architecture:
1. **Prediction Phase**: SpawnPredictor calculates upcoming obstacle spawns and determines which will carry nests
2. **Execution Phase**: Enhanced spawners follow pre-calculated plans while EarlyWarningSystem triggers indicators based on predictions

**Key Technical Requirements**:
- Maintain prediction buffer covering 3-4 seconds of future gameplay
- Calculate exact world positions for predicted nests
- Synchronize predictions with actual spawning system
- Provide configurable lead times for different warning types
- Ensure predictions account for current stage parameters and difficulty settings

**Success Criteria**:
- Nest indicators appear 3-4 seconds before nest becomes visible
- Predictions maintain accuracy within 0.2 seconds of actual spawns
- System handles stage transitions and difficulty changes gracefully
- Performance impact minimal (< 1ms per prediction update)

---

## Performance Optimization Addendum (Anti‑Burst, Low-GC, Stable Frame Time)

This addendum strengthens the design to avoid distance-based spawn bursts and cleanup spikes.

### Goals
- Keep predictor+spawner CPU < 1.0 ms/frame average, ~0.3 ms typical
- Prevent multiple spawn/cleanup operations landing on the same frame
- Minimize GC churn with pooling and per-frame budgets

### 1) Time-based Scheduling and Anti‑Burst Rules
- Convert predictions to time-based schedule: `spawn_time = now + predicted_distance / world_speed`
- On world speed change, rescale remaining `spawn_time` values
- Enforce throttles when executing the timeline:
  - `min_spawn_spacing_ms` (default 100 ms)
  - `spawn_events_per_frame_max` (default 1)
  - `cleanup_events_per_frame_max` (default 3–4)
- Clamp big `delta`: if `delta > 0.1`, execute at most one spawn this frame

### 2) Frame Work Budget with Queues
Maintain queues and stop when budget is spent:
```gdscript
@export var frame_budget_ms: float = 0.6

func _physics_process(_delta: float) -> void:
    var start_us := Time.get_ticks_usec()
    var spawns := 0
    while spawn_queue.size() > 0:
        _execute_one_spawn(spawn_queue.pop_front())
        spawns += 1
        if spawns >= spawn_events_per_frame_max:
            break
        var elapsed_ms := (Time.get_ticks_usec() - start_us) / 1000.0
        if elapsed_ms > frame_budget_ms:
            break

    var cleans := 0
    while recycle_queue.size() > 0 and cleans < cleanup_events_per_frame_max:
        _recycle_one(recycle_queue.pop_front())
        cleans += 1
```

### 3) Object Pooling (Per Type) with Prewarm
- Pool per obstacle type; prewarm to expected concurrency
- Checkout from pool on spawn; return on cleanup
- When pooled: `visible = false`, `process_mode = Node.PROCESS_MODE_DISABLED`, remove from `"obstacles"` group
- If pool empty: instantiate; if over capacity: free gradually obeying cleanup budget

### 4) Cleanup Delegation
- Replace direct `queue_free()` in obstacle with signal `offscreen_exited(obstacle)` to recycler; budget the recycle work

### 5) Predictor ↔ Spawner Sync
- Predictor owns ordered timeline with `spawn_time`
- Spawner consumes due items only if within per-frame budget
- Use deterministic RNG so prediction and execution match

### 6) Telemetry without Console Spam
- Expose counters: `timeline_size`, `spawn_queue_len`, `recycle_queue_len`, `pool_free[type]`
- `PerformanceMonitor` can read and print these only when `enable_console_output` is ON

### 7) Exported Tuning Knobs
- `prediction_lookahead_time: float = 4.0`
- `prediction_refresh_interval: float = 0.5`
- `min_spawn_spacing_ms: int = 100`
- `spawn_events_per_frame_max: int = 1`
- `cleanup_events_per_frame_max: int = 4`
- `frame_budget_ms: float = 0.6`
- `pool_enabled: bool = true`
- `pool_prewarm_per_type: int = 6`

### 8) Edge Cases
- Stage transition: rebuild predictions, keep pools
- Tab-out big delta: execute at most one spawn; repopulate timeline next frame
- Speed spikes: rescale remaining `spawn_time` values and keep spacing

### 9) Acceptance Checks
- No periodic 2–4s spikes with logging off; physics time < 2 ms typical
- Horizon keeps 3+ upcoming spawns populated at 300 px/s, 4 s window
- Queue lengths remain bounded (spawn ≤ 3, recycle ≤ 8) during play