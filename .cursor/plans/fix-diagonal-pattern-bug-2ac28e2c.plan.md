<!-- 2ac28e2c-9891-4fab-ad1b-fcb97657f6db 2ff75224-a909-42a1-9352-44f37b023832 -->
# Fix Diagonal Pattern Overlay Bug

## Problem

The diagonal pattern overlay isn't updating correctly on the second capacity reduction because `queue_free()` doesn't remove the node immediately, causing multiple overlays to exist simultaneously.

## Solution: Reuse Single Overlay Node (Option 3)

### Changes to `scripts/ui/ui_energy_bar.gd`

1. **Add a cached reference** for the diagonal pattern overlay node:

   - Add at the top with other internal references (after line 42):
     ```gdscript
     var diagonal_pattern_overlay: TextureRect = null
     ```


2. **Refactor `create_diagonal_pattern_overlay()` to `update_diagonal_pattern_overlay()`**:

   - Rename the function to better reflect that it updates (not always creates)
   - Check if `diagonal_pattern_overlay` exists:
     - If it exists: just update its `offset_left` and `offset_right` properties
     - If it doesn't exist: create it once and cache the reference
   - Handle the case where locked capacity becomes 0 (hide the overlay instead of deleting it)

3. **Update all calls** to use the new function name:

   - Line 151 in `setup_ui_elements()`
   - Line 335 in `update_capacity_display()`

### Implementation Details

The new function logic:

- **If locked_capacity_percent <= 0**: Hide existing overlay if it exists
- **Else if overlay doesn't exist**: Create new TextureRect and cache reference
- **Else**: Update the cached overlay's position (offset_left)
- Always ensure overlay is visible when there's locked capacity

This approach is more efficient and avoids the queue_free() timing issue entirely.