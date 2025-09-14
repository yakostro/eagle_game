### UI Tutorial Overlay — Stage-based PNG Hints

#### Goal
Show a small, non-blocking tutorial PNG overlay at the start of Stage 1 (movement keys) and a different PNG at the start of Stage 2 (fish shortcuts). It should sit on the UI canvas and auto-hide after a short duration. It should not dismiss on user input.

#### Player Experience
- A short fade-in overlay appears at the very start of the stage.
- Stage 1: movement keys image (WASD/arrows) for a quick reminder.
- Stage 2: fish interaction shortcuts image.
- The overlay auto-hides after a short duration. No input-based dismissal.
- It should not block controls once dismissed and should not reappear during the same stage unless explicitly retriggered.

#### Assets
- Movement tutorial PNG: `sprites/ui/tutorials/movement_keys.png`
- Fish tutorial PNG: `sprites/ui/tutorials/fish_shortcuts.png`
- These must be small, readable at 1080p, and legible with a subtle dark backdrop.

#### Scene Architecture (Editor)
- New scene: `scenes/ui/ui_tutorial_overlay.tscn`
  - Root `Control` named `UITutorialOverlay` (full-rect, under the game `CanvasLayer`).
  - Child `TextureRect` named `TutorialImage` (centered, `KEEP_ASPECT_CENTERED`).

Naming: Node names use CamelCase; script filename will be snake_case. Use exported `NodePath`s for child references (avoid direct `$`).

#### Behavior (Concept)
- The overlay chooses which PNG to show based on the current stage id.
- Fades in on stage start and auto-hides after a configurable time (no input dismissal).
- Only shows once per stage entry by default. Re-showing can be triggered manually if needed (e.g., via debug).
- Z-order: placed after other UI under `Game/CanvasLayer` so it renders on top of existing HUD and messages.

#### Integration Points
- Instance `ui_tutorial_overlay.tscn` under `Game/CanvasLayer` in `scenes/game_steps/game.tscn`.
- On stage transitions, the stage system emits a signal (e.g., `stage_started(stage_id: int)`).
- The overlay listens for this signal and calls `show_for_stage(stage_id)`.
- Map stage 1 → movement PNG; stage 2 → fish PNG. Other stages may be unmapped (no overlay).

#### Tuning / Balancing Variables
- Show duration (seconds) before auto-hide.
- Fade-in and fade-out durations.
- Stage-to-texture mapping (data-driven; change without code).

#### Signals & Events
- Expected input signal: `stage_started(stage_id)` from the stage system or `Game`.
- Optional overlay emits:
  - `tutorial_shown(stage_id)` when visible.
  - `tutorial_dismissed(stage_id)` when hidden.
- These can be used for analytics/telemetry or to gate early objectives if required.

#### Editor Setup Checklist
1) Import PNGs to `sprites/ui/tutorials/` with proper filtering settings for crisp UI.
2) Create `scenes/ui/ui_tutorial_overlay.tscn` with nodes described above.
3) Add overlay instance under `Game/CanvasLayer` in `scenes/game_steps/game.tscn` and keep it hidden by default.
4) Ensure overlay sits after other UI nodes in the scene tree to render on top.
5) Connect stage start to overlay (`stage_started(stage_id)` → `show_for_stage(stage_id)`). If the signal does not exist yet, add it at the stage manager level and emit on each stage begin.
6) Configure stage-to-texture mapping: 1 → movement_keys.png, 2 → fish_shortcuts.png.
7) Test at 1080p and one smaller resolution to confirm readability and layout.

#### Edge Cases / UX Notes
- Overlay ignores user input; only timer-based dismissal applies.
- Avoid re-showing the overlay on quick respawns within the same stage unless desired.
- Do not block input; gameplay continues normally while the overlay is visible.
- Consider controller input parity in the future (assets may need gamepad icons).

#### Future Extensions (Optional)
- Add per-stage positioning or size overrides for the image.
- Support a sequence of images or localized variants.
- Persist a “seen” flag across sessions to skip tutorials for returning players.

---

### Prompt for Coding Agent

**High-level task**: Implement a reusable `UITutorialOverlay` UI scene that displays stage-specific PNG hints at the start of a stage. Integrate it into `game.tscn` under the main `CanvasLayer` and trigger it on stage start for Stage 1 (movement keys) and Stage 2 (fish shortcuts). The overlay must auto-hide on a timer and must not dismiss on user input.

**Decision (implementation concept)**:
- Create `scenes/ui/ui_tutorial_overlay.tscn` with `Control` root `UITutorialOverlay` and a child `TutorialImage` (`TextureRect`).
- Add `scripts/ui/ui_tutorial_overlay.gd`, using exported `NodePath`s to reference `TutorialImage`. Expose tuning exports: show duration, fade durations, and a `Dictionary` mapping stage ids to `Texture2D` resources.
- Instance the overlay in `scenes/game_steps/game.tscn` under `CanvasLayer` (after existing UI nodes for proper Z-order). Wire the exported `NodePath`s in the inspector.
- Connect the stage system signal (or emit one if missing) to call `show_for_stage(stage_id)`. Map stage 1 → movement image, stage 2 → fish image. Ensure one-time display per stage by default.
- Use clean node naming (CamelCase) and GDScript file naming (snake_case). Avoid direct `$` references; use exported `NodePath`s. Keep debugging output minimal.


