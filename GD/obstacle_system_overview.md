## Obstacle System — Current State (Godot 4.2)

### Purpose
High-level snapshot of how obstacles are configured, spawned, and progressed through stages. This is written for designers and engineers aligning on behavior before coding changes.

### Architecture Overview
- **StageConfiguration (Resource)**: Holds stage-level knobs: world speed, spawn weights per obstacle type, spacing range, and simple completion rule (timer or nests spawned). Also includes per-type vertical rules (mountain height band, stalactite height band, island gap offsets) and toggles for fish and nests.

- **StageManager (Singleton Node)**: Loads a `StageConfiguration` (`res://configs/stages/…`) by stage number, tracks timer/nest progress, and emits `stage_changed` with the active config. After manual stages it switches to an auto-difficulty system that continuously produces and applies modified configs while retaining the same signal flow.

- **ObstacleSpawner (Node2D)**: Owns references to obstacle scenes (mountain variants array, stalactite, floating island). Builds a weighted table from the current config and uses distance-based logic to place obstacles ahead of the screen edge. Applies per-type height/offset settings from the active stage to each spawned instance, syncs world speed, then positions the instance off-screen right.

- **BaseObstacle (StaticBody2D)**: Shared behavior for all obstacles. Each instance moves left at the configured world speed and frees itself when fully off-screen. Child classes implement vertical placement. Sprite size calculations account for both sprite and root scaling to keep cleanup and positioning correct.

### Runtime Flow
1. StageManager loads a stage config and emits `stage_changed`.
2. ObstacleSpawner updates weights, spacing, and movement speed; rebuilds its weighted types list.
3. Spawner schedules the next spawn X using the current spacing range; when the right edge approaches, it instantiates a weighted type.
4. The new obstacle receives per-type vertical rules from the stage, sets speed, and positions off-screen right.
5. Each obstacle self-moves and self-cleans when out of view. Spawner emits `obstacle_spawned` for nest coordination; StageManager tracks totals and advances stages by timer or nest count.

### Editor Setup Checklist
- Assign obstacle scenes in the spawner: mountain variants array, stalactite, floating island.
- Optionally link the nest spawner to receive `obstacle_spawned`.
- Ensure each obstacle scene:
  - Root inherits from BaseObstacle.
  - Contains a child `Sprite2D` named `Sprite2D`.
  - Provides a `NestPlaceholder` (Marker2D) if it can carry a nest.
  - Exposes a consistent way to set its vertical rules (method or exported properties) used by the spawner.

### Balancing Levers (for designers)
- **Pace**: `world_speed` and the spacing range (`min_obstacle_distance`–`max_obstacle_distance`).
- **Variety**: Weighted mix of mountains, stalactites, islands per stage.
- **Vertical challenge**: Mountain height band; stalactite height band; island min top/bottom gap offsets.
- **Systems**: Toggle fish and nests; adjust fish intervals and nest skip counts.
- **Stage length**: Timer seconds or required nests spawned.

### Contracts/Assumptions
- Spawner receives all stage-driven values via `stage_changed` and applies them immediately.
- Obstacle scenes accept vertical rule inputs either by dedicated methods or exported properties named consistently with the spawner’s expectations.
- Cleanup uses actual sprite dimensions times combined scales, preventing off-screen artifacts even when nodes scale differently.

### Known Gaps and Safe Enhancements (small steps)
- **Repeat variety control**: The config exposes `same_obstacle_repeat_chance`, but the spawner doesn’t currently enforce it. Introduce a soft anti-repeat rule to reduce consecutive identical types without eliminating them.
- **Unified obstacle API**: Standardize on a single method per type (e.g., `set_mountain_height_range`, `set_stalactite_height_range`, `set_island_offsets`) to remove dual method/property branches in the spawner.
- **Editor NodePaths**: Where nodes are looked up by fixed names, prefer exported `NodePath`s for robustness and scene flexibility.

### Prompt for Coding Agent
- **High-level task**: Add lightweight repeat variety control to obstacle selection, honoring `same_obstacle_repeat_chance` from the active stage to avoid long streaks of the same obstacle type.

- **Decision (concept)**:
  - Track the last selected obstacle type name in the spawner.
  - On each selection, if the random pick matches the last type, roll a chance: with probability equal to `same_obstacle_repeat_chance`, accept; otherwise re-pick once (single re-roll). This preserves weights while curbing streaks without heavy bias or loops.
  - Keep this logic optional and data-driven by using the stage’s configured value; designers can set 0.0 (never repeat back-to-back) through 1.0 (no restriction).
  - Do not change stage file formats; only read the existing value and apply the logic inside the spawner’s weighted selection.


