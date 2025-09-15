### Off-screen Nest Indicator – Scene Design

**Goal**
- When a nest is spawned off-screen to the right, show a blinking nest icon at the right visible edge of the screen, aligned to the nest’s world Y. Hide the icon the moment before the real nest becomes visible.

**Player experience**
- The indicator nudges the player to move right without breaking immersion.
- It appears only while the nest is off-screen, blinks calmly, and disappears as the nest arrives on-screen.

## UX rules
- **Placement**: Rightmost visible screen edge (respecting safe margin), same Y as the nest’s world Y projected into viewport.
- **Visibility**: Shown only if nest’s world X is to the right of camera’s right frustum boundary; hidden otherwise.
- **Blinking**: Soft fade in/out loop; no harsh strobe.
- **Palette**: Use colors from `configs/ui/ui_palette_default.tres`.
- **One-at-a-time**: Only one nest is active at a time; indicator supports single target.

## Scene and node architecture
- **Where**: Add a UI node to `scenes/game_steps/game.tscn` under its existing `CanvasLayer` as a sibling of other UI.
- **Node name**: `UIOffscreenNestIndicator` (camelCase).
- **Script**: `scripts/ui/ui_offscreen_nest_indicator.gd` (snake_case).
- **Child nodes**:
  - `TextureRect` (icon sprite). Anchored to right edge; size and texture configurable.
  - `AnimationPlayer` or `Tween` (for blinking).

## Data flow and signals
- **Inputs**
  - From `NestSpawner` (existing in `game.tscn`):
    - `nest_spawned_offscreen(nest_world_position: Vector2)` – emitted when a nest is created to the right and still outside the camera.
    - `nest_about_to_enter_view()` or `nest_became_visible()` – emitted right before/in the moment the nest becomes visible. If not available, can derive via a visibility check each frame.
  - From `Camera2D` (in `game.tscn`): Used to compute camera frustum and world→viewport transform.

- **UIOffscreenNestIndicator responsibilities**
  - On `nest_spawned_offscreen`: project provided world Y into viewport, clamp to screen bounds, place icon at `viewport_width - margin_right, projected_y` and start blink.
  - Each frame (or on camera move): re-project Y to follow camera vertical movement while the nest stays off-screen.
  - Hide immediately on `nest_about_to_enter_view`/`nest_became_visible`, or when computed visibility test says the nest X ≤ camera right edge.

## Visibility logic (high level)
- Compute camera right boundary in world space: `camera_global_position.x + half_viewport_width / zoom.x` (conceptual). Compare with `nest_world_position.x`.
- If `nest_world_position.x` > camera right boundary → show indicator; else hide.
- Project world Y to viewport Y using camera transform, clamp within safe vertical margins (top/bottom padding).

## Tunable parameters (exported)
- **iconTexture**: Texture for the nest indicator.
- **iconSize**: Optional override to scale the icon.
- **rightMargin**: Padding from the right edge (e.g., 20–48 px).
- **verticalPadding**: Top/bottom clamp padding.
- **blinkDuration**: Time for fade in/out cycle.
- **minHideLeadTime**: If using proactive hide, how early to remove indicator before nest appears (e.g., 0.2–0.3s).
- **cameraPath**: `NodePath` to `Camera2D`.
- **nestSpawnerPath**: `NodePath` to `NestSpawner` for signals.
- **palette**: Reference to UI palette resource.

## Editor setup (in Godot)
1. Open `scenes/game_steps/game.tscn`.
2. Under `CanvasLayer`, add a `Control` node named `UIOffscreenNestIndicator` with script `scripts/ui/ui_offscreen_nest_indicator.gd`.
3. Add a `TextureRect` child named `Icon`. Set `stretch_mode=KEEP_CENTERED` or appropriate, and disable mouse filters.
4. Add an `AnimationPlayer` (or animate via script Tween) to handle blinking.
5. In the `UIOffscreenNestIndicator` inspector, set exported paths:
   - `cameraPath` → `../..` to root then `Camera2D` in the scene.
   - `nestSpawnerPath` → `../../Spawners/NestSpawner`.
   - `palette` → `configs/ui/ui_palette_default.tres`.
   - Assign `iconTexture` (new or existing nest icon asset).
6. Ensure anchors for `UIOffscreenNestIndicator` are full-rect; actual placement is done by positioning the `Icon` at runtime to the right edge.

## Edge cases
- If the nest is spawned within view, never show the indicator.
- If the player scrolls vertically, reproject and move the icon’s Y accordingly.
- If the nest despawns or a new nest is queued, hide the indicator immediately.

## Performance
- Only perform world→viewport projection when the indicator is visible or the camera moved.
- Avoid per-frame heavy math; use the existing `Camera2D` transforms.

## Art and palette
- Use a readable icon silhouette at small sizes; ensure contrast with the background using the palette’s light tones for icon fill and darker stroke as needed.

## QA checklist
- Spawning nest off-screen shows indicator on the right edge at correct Y.
- As the camera approaches the nest, the indicator disappears slightly before the nest is visible.
- Vertical camera motion keeps the indicator aligned with nest Y.
- Indicator never appears when nest is within screen.

## Prompt for coding agent
**High-level task**
- Implement `UIOffscreenNestIndicator` that shows a blinking nest icon at the right screen edge aligned to the off-screen nest’s world Y, and hides just before the nest becomes visible.

**Decision / approach**
- Add `UIOffscreenNestIndicator` (Control) under `CanvasLayer` in `game.tscn`, with a `TextureRect` child for the icon and an `AnimationPlayer`/Tween for blinking.
- Export `NodePath`s for `Camera2D` and `NestSpawner`, plus tunables for `iconTexture`, `rightMargin`, `verticalPadding`, `blinkDuration`, `minHideLeadTime`, `palette`.
- Connect to `NestSpawner` signals (`nest_spawned_offscreen`, `nest_about_to_enter_view` or `nest_became_visible`). If such signals don’t exist, emit them from spawner when spawning to the right or detect visibility in the UI using camera bounds.
- Compute camera right world boundary; if `nest_world_position.x` is beyond it, show the indicator. Project nest world Y to viewport Y using `Camera2D` and place the icon at `(viewport_width - rightMargin, clampedY)`.
- Start a gentle blink animation while visible; stop and hide when nest is about to enter or becomes visible, or if visibility test fails.
- Respect naming conventions (node camelCase, script snake_case). Use the project’s UI palette for colors. Prefer `@export var ...: NodePath` instead of direct `$` references.


