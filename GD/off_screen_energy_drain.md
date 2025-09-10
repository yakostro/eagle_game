### Off-Screen Energy Drain (Eagle)

#### Overview
The eagle should lose energy whenever it is off the visible screen area. This mechanic nudges the player to stay within the camera’s view and punishes drifting out of bounds. Default drain is 5 energy per second and must be easily tunable.

#### Player Experience Goals
- Subtle, constant pressure to remain visible.
- No surprise insta-death: drain is continuous and predictable.
- Optional soft feedback (SFX/UI ping) when first going off-screen; avoid spam during continuous drain.

#### System Design
- Detection: compute the active Camera2D’s world-space screen rectangle each frame and check if the eagle’s position (or a small padding rect) lies outside.
- Separation of concerns: keep a dedicated “off-screen” state check on the eagle and let the energy update function read that state to apply additional drain.
- Authority: all tunables are defined in `EnergyConfig` and applied to the eagle at runtime. Editor-exported fields on the eagle are proxies (for visibility) but are overwritten by `EnergyConfig` in `_ready()`.
- Enforcement: gameplay scenes must provide a `BalanceProvider` with a valid `EnergyConfig`. Missing config should produce a clear error (prefer assert or `push_error`) and off-screen drain should be considered misconfigured.

#### Parameters (tweakables) — Required in EnergyConfig
These fields live in `scripts/systems/energy_config.gd` and are set per preset (e.g., `configs/energy/energy_config_default.tres`).
- enable_offscreen_energy_loss: bool (default true)
- offscreen_energy_loss_per_second: float (default 5.0)
- offscreen_bounds_margin: float (default 32.0)

Eagle may expose equivalent exported fields for editor visibility, but they are not the source of truth and must be overwritten from `EnergyConfig` in `_ready()`.

#### Integration Points
- EnergyConfig (required): extend `scripts/systems/energy_config.gd` with the three fields above and add them to `configs/energy/energy_config_default.tres`.
- BalanceProvider (existing): ensure gameplay scenes provide a `BalanceProvider` node that references the active `EnergyConfig` preset.
- Eagle script: add an `is_off_screen()` check using the active camera and margin from `EnergyConfig`.
- Energy update: when off-screen and `enable_offscreen_energy_loss` is true, add `offscreen_energy_loss_per_second * delta` to existing loss, then clamp and reuse existing death checks.
- Camera source: prefer `camera_path: NodePath` on the eagle; if empty, use `get_viewport().get_camera_2d()`.

#### Edge Cases
- Paused game: no drain while paused.
- Death: clamp energy at 0 and trigger existing death flow.
- Scenes without a camera yet: skip check until a camera is available.
- Missing BalanceProvider/EnergyConfig: treat as configuration error; surface via assert/`push_error`. Off-screen drain values must not silently fall back.

#### Testing Checklist
- Move eagle partially and fully off each edge; verify drain starts/stops correctly.
- Toggle `enable_offscreen_energy_loss` in the preset; verify behavior.
- Adjust `offscreen_bounds_margin` in the preset; confirm sensitivity to boundaries.
- Confirm default drain (5/sec) interacts correctly with other drains/gains.
- Remove or misconfigure `EnergyConfig` and confirm the error is surfaced.

---

### Coding Agent Prompt

- High-level task: Implement off-screen energy drain for the eagle that subtracts N energy per second (default 5) only while the eagle is outside the active camera’s visible area. All tunables are sourced from `EnergyConfig` presets.

- Decision (approach):
  - Extend `scripts/systems/energy_config.gd` with required fields:
    - `enable_offscreen_energy_loss: bool = true`
    - `offscreen_energy_loss_per_second: float = 5.0`
    - `offscreen_bounds_margin: float = 32.0`
  - Update `configs/energy/energy_config_default.tres` to include these fields with defaults.
  - In `Eagle._ready()`, assert a valid `BalanceProvider.energy_config` exists and load these fields into the eagle (overwriting any editor-exported proxies). Do not silently fall back.
  - Implement `is_off_screen()` using the active `Camera2D` world-space screen rect plus margin.
  - In the eagle’s energy update, when off-screen and enabled, subtract `offscreen_energy_loss_per_second * delta`, clamp, and reuse existing death checks.
  - Keep UI/SFX minimal: optionally trigger a one-time UI hint on off-screen enter; avoid continuous spam.
