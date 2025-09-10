## UI Instant Text Feedback Refactor (High-Level Design)

### Goals
- **Decouple responsibilities**: `UIMessage` handles queued textual messages only (nest incoming, nest missed, etc.).
- **Independent instant text feedback**: A separate scene/script (`UIInstantTextFeedback`) that can be called directly to show a floating instant feedback at a world position (currently energy with icon).
- **Juice**: The feedback shows for a configurable duration, drifts upward, and fades out. All behavior is tweakable in Inspector.

### Scope
- Keep the existing `res://scenes/ui/ui_immediate_text_feedback.tscn` as the base visual, but rename it to `res://scenes/ui/ui_instant_text_feedback.tscn`, give it its own script and API.
- Remove any instant feedback responsibilities from `res://scripts/ui/ui_message.gd`.
- Public API accepts `(world_x, world_y, amount)` for display, plus optional overrides if we need them later.

### Responsibilities Split
- **UIMessage (messages only)**
  - Maintains message queue and timing for message types: `NEST_INCOMING`, `NEST_MISSED`.
  - Shows/hides the nest notice and morale pop only.
  - No direct control of energy loss instant feedback.

- **UIInstantTextFeedback (instant text feedback only; currently used for energy)**
  - Displays a single floating feedback with text like `-<amount>` plus the energy icon.
  - Takes a world position and converts to screen/canvas position using the active `Camera2D`.
  - Plays a tween: rise up over time and fade-out; hides/queues free as needed.
  - Exposes Inspector properties for: duration, rise distance, start alpha, end alpha, easing, delay (if any), and screen offset.

### Scene & Script Architecture
- Scene: `res://scenes/ui/ui_instant_text_feedback.tscn` (rename from `ui_immediate_text_feedback.tscn`)
  - Root: `UiImmediateTextFeedback: CanvasLayer`
  - Child: `EnergyFeedbackContainer: Control` (holds `EnergyLossLabel` + `Icon`)
  - Attach new script: `res://scripts/ui/ui_instant_text_feedback.gd`

- Script: `ui_instant_text_feedback.gd` (new)
  - Exports:
    - `duration: float` (seconds)
    - `rise_distance: float` (pixels)
    - `start_alpha: float` (0..1)
    - `end_alpha: float` (0..1)
    - `screen_offset: Vector2`
    - `easing: float` (0..1, curve-like; or use built-in `Tween.EASE_*` + `TRANS_*` enums)
    - `camera_path: NodePath` (optional; auto-find if empty)
    - `label_path: NodePath` and `container_path: NodePath` (explicit wiring option)
  - Public method:
    - `show_feedback_at(world_position: Vector2, amount: int) -> void`
      - Updates label to `"-<amount>"`.
      - Converts `world_position` to screen and applies `screen_offset`.
      - Makes container visible, creates a Tween, animates position Y up and modulate.a to `end_alpha` over `duration`.
      - Hides on complete.

### Editor Wiring / Usage
- Keep `UIInstantTextFeedback` node under the main `CanvasLayer` in `game.tscn`.
- Attach `ui_instant_text_feedback.gd` to the scene root if not already.
- In `UIMessage` remove any calls/exports related to energy feedback.
- From gameplay code (e.g., `Eagle` on hit) call:
  - Get node: `UIInstantTextFeedback` → script method `show_feedback_at(eagle.global_position, amount)`.

### Parameter Defaults (initial tuning)
- `duration = 0.9`
- `rise_distance = 40`
- `start_alpha = 1.0`
- `end_alpha = 0.0`
- `screen_offset = Vector2(-80, 0)`
- `easing`: smooth out (use `TRANS_SINE`, `EASE_OUT`)

### Migration Steps
1) Add new script `ui_instant_text_feedback.gd` and attach to `UiImmediateTextFeedback` scene (and rename the scene file to `ui_instant_text_feedback.tscn`).
2) Remove energy-loss related pieces from `ui_message.gd`:
   - Enum entry `ENERGY_LOSS` and handling functions.
   - Node resolution for `EnergyFeedbackContainer` and label.
   - Signal connection to `eagle_hit` in this script.
3) Update gameplay trigger (e.g., `Eagle` or damage handler) to call `UIInstantTextFeedback.show_feedback_at(position, amount)` directly.
4) Expose Inspector properties and tune (duration, rise distance, alphas, offset).

---

## Coding Agent Prompt

### High-Level Task
Refactor the UI so that queued textual messages remain in `UIMessage` while the instant text feedback becomes an independent, directly callable component with tweened rise-and-fade behavior (currently used for energy with the energy icon).

### Decision / Concept
- Rename the existing `ui_immediate_text_feedback.tscn` to `ui_instant_text_feedback.tscn` and attach a new script that exposes a clean public API and Inspector-tweakable parameters. Remove energy responsibilities from `ui_message.gd`. Gameplay code calls the instant feedback directly with world position and amount.

### Deliverables
1. New script: `scripts/ui/ui_instant_text_feedback.gd` implementing the public API and tweens.
2. Edits to `ui_message.gd` removing energy-loss responsibilities, enums, and node-paths.
3. Ensure `game.tscn` still instances `UIInstantTextFeedback` and that calling the public API from gameplay works.

### Naming Consistency Changes
- Class in `ui_message.gd`: rename `class_name UIFeedback` to `class_name UIMessage`.
- Use generic names: avoid "energy_feedback" in code; use "instant_text_feedback" for the independent component.
- Keep node names CamelCase (e.g., `UIInstantTextFeedback`) and script filenames snake_case (e.g., `ui_instant_text_feedback.gd`).


