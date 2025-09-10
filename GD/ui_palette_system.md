### UI Palette and UI Refactor (High-Level Design)

#### Goal
Create a single editable palette used by UI elements. Replace hardcoded colors with named palette tokens so we can tweak visuals from one place.

#### Constraints
- No semantic naming for now. Use the exact token names below.
- No central wiring or theme propagation for now — do not implement unless stated explicitly.
- Keep node names camelCase and script files snake_case.
- Prefer exported `NodePath` fields over direct `$Child` references.
- Expose tweakable variables via `@export` for balancing.

#### Palette Tokens (names and hex)

| Name     | Hex    |
|----------|--------|
| Yellow1  | #755F27|
| Yellow2  | #C59D39|
| Yellow3  | #E8B942|
| Red2     | #CC4848|
| Red3     | #F45353|
| Purple1  | #38263E|
| Black    | #120F16|
| White    | #E3DDE8|

These values will live in a single palette resource instance so they can be changed in one place.

#### Files and placement (to be created by coding agent)
- `scripts/ui/ui_palette.gd` — Resource script that exposes exported `Color` fields for each token above (no logic).
- `configs/ui/ui_palette_default.tres` — An instance of `UiPalette` filled with the hex values.

#### Target UI elements (first refactor pass)
- `UIInstantTextFeedback`
- `UIEnergyBar`
- `MoralePopContainer`
- `StageHud`

Each target will:
- Add `@export var palette: UiPalette`.
- Add exported `NodePath` fields for any child nodes whose colors are controlled (labels, progress bars, icons, panels).
- In `_ready()`, resolve nodes via `get_node(nodePath)` and apply colors from the palette tokens listed below.
- Remove hardcoded colors. Keep behavior unchanged otherwise.

#### Initial token usage suggestions (can be adjusted later)
- UIInstantTextFeedback: default text `White`; positive/boost vibes lean `Yellow3`; warnings/errors `Red3` or `Red2`.
- UIEnergyBar: fill `Yellow2` (optionally `Yellow3` at max), background `Black`, text/marks `White`.
- MoralePopContainer: positive pop `Yellow3`; negative pop `Red3`.
- StageHud: primary text `White`; accent or emphasis `Yellow2`; panel/backing `Purple1` (dark) if needed.

#### Editor/scene notes
- Store `ui_palette_default.tres` in `configs/ui/` and assign it to the exported `palette` field on each UI node in scenes.
- Do not add a global theme broadcaster or autoload for palette now.
- Keep all current UI layout and animations intact; only replace color sources.

---

### Coding Agent Prompt

High-level task:
Implement a token-based UI palette and refactor specified UI scripts to read colors from a shared `UiPalette` resource, without introducing central wiring.

Decision (architecture):
Use a custom `Resource` (`UiPalette`) with exported `Color` fields named exactly: `Yellow1`, `Yellow2`, `Yellow3`, `Red2`, `Red3`, `Purple1`, `Black`, `White`. Each target UI script has `@export var palette: UiPalette` and exported `NodePath` references to the nodes it colorizes. Colors are applied in `_ready()`; no groups/autoload propagation yet.

Steps:
1) Create `scripts/ui/ui_palette.gd` (Resource). Export the eight `Color` properties.
2) Create `configs/ui/ui_palette_default.tres` and set the following values:
   - Yellow1 `#755F27`
   - Yellow2 `#C59D39`
   - Yellow3 `#E8B942`
   - Red2 `#CC4848`
   - Red3 `#F45353`
   - Purple1 `#38263E`
   - Black `#120F16`
   - White `#E3DDE8`
3) Refactor `UIInstantTextFeedback`:
   - Export `palette` and required `NodePath` fields (e.g., `labelPath`).
   - Apply `White` for default text; allow choosing `Yellow3/Red3` for variants if used.
4) Refactor `UIEnergyBar`:
   - Export `palette` and nodes for bar fill/back/text.
   - Use `Yellow2` (fill), `Black` (background), `White` (text/marks).
5) Refactor `MoralePopContainer`:
   - Export `palette` and node paths; use `Yellow3` (positive), `Red3` (negative).
6) Refactor `StageHud`:
   - Export `palette` and node paths; use `White` for text, `Yellow2` for emphasis, optional `Purple1` for panel.
7) Remove any remaining hardcoded colors in these scripts. Do not add central wiring or theme broadcasting.

Do not implement central wiring unless explicitly requested in chat.


