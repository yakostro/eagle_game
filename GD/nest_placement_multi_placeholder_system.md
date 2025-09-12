# Nest Placement Multi-Placeholder System Design

## Overview
The current nest spawning system places nests on obstacles using a single `NestPlaceholder` marker. This design extends that system to support multiple nest placeholders per obstacle, with intelligent placement based on screen visibility constraints.

## Current Architecture Analysis
- **BaseObstacle**: Provides `get_nest_placeholder()` and `has_nest_placeholder()` methods
- **NestSpawner**: Handles obstacle selection and nest instantiation
- **Obstacles**: Mountains have 6 placeholders, Floating Islands have 1 placeholder
- **Placement Logic**: Currently uses the first `NestPlaceholder` found

## Design Goals
1. **Multiple Placeholders**: Support several `NestPlaceholder` nodes per obstacle
2. **Visibility Guarantee**: Ensure nests appear within visible screen area
3. **Height Variation**: Use different placeholder heights for visual variety
4. **Maintain Simplicity**: Keep the existing spawner interface intact

## System Architecture

### 1. Enhanced BaseObstacle Methods
Replace single placeholder logic with multi-placeholder support:

**Current:**
```gdscript
func get_nest_placeholder() -> Marker2D
func has_nest_placeholder() -> bool
```

**Enhanced:**
```gdscript
func get_all_nest_placeholders() -> Array[Marker2D]
func get_visible_nest_placeholders(screen_height: float, bottom_offset: float) -> Array[Marker2D]
func has_visible_nest_placeholders(screen_height: float, bottom_offset: float) -> bool
```

### 2. Screen Visibility Logic
**Visibility Calculation:**
- Calculate obstacle's world position when spawned
- Filter placeholders where `placeholder.global_position.y < screen_height - bottom_offset`
- `bottom_offset` ensures nests don't stick to screen edge (e.g., 100-200 pixels)

**Key Considerations:**
- Obstacle scaling affects placeholder positions
- Both root node scaling and sprite scaling must be accounted for
- Global position calculation includes obstacle's spawn position

### 3. Random Selection Algorithm
**Selection Process:**
1. Get all nest placeholders from obstacle
2. Filter placeholders by visibility constraint
3. If visible placeholders exist, randomly select one
4. If no visible placeholders, skip nest placement (fail gracefully)

### 4. NestSpawner Integration
**Enhanced Spawning Logic:**
```gdscript
func spawn_nest_on_obstacle(obstacle: BaseObstacle):
    var screen_height = get_viewport().get_visible_rect().size.y
    var bottom_offset = nest_visibility_offset  # configurable parameter
    
    var visible_placeholders = obstacle.get_visible_nest_placeholders(screen_height, bottom_offset)
    if visible_placeholders.is_empty():
        return  # Skip nest placement
    
    var selected_placeholder = visible_placeholders[randi() % visible_placeholders.size()]
    # ... rest of nest spawning logic
```

## Scene Setup Requirements

### Mountain Scenes (Already Implemented)
- **MountainA**: 6 `NestPlaceholder` nodes at different heights
- **MountainB**: 1 `NestPlaceholder` node  
- **MountainC**: 1 `NestPlaceholder` node

### Floating Island Scenes (Enhancement Needed)
- **Current**: 1 `NestPlaceholder` node
- **Recommended**: 2-3 `NestPlaceholder` nodes at different heights on the island surface

### Placeholder Naming Convention
- Use sequential naming: `NestPlaceholder`, `NestPlaceholder2`, `NestPlaceholder3`, etc.
- Alternative: Group under a parent node for better organization

## Configuration Parameters

### New Export Variables for NestSpawner
```gdscript
@export var nest_visibility_offset: float = 150.0  # Pixels from screen bottom
@export var debug_placeholder_selection: bool = false  # Show selection process
```

### Stage Configuration Integration
Add to `StageConfiguration` resource:
```gdscript
@export var nest_bottom_offset: float = 150.0  # Stage-specific visibility offset
```

## Edge Cases and Fallbacks

### No Visible Placeholders
- **Behavior**: Skip nest placement gracefully
- **Logging**: Debug message explaining why nest was skipped
- **Metrics**: Track skipped nests for balancing

### Very Tall Mountains
- **Issue**: All placeholders might be above screen when mountain spawns low
- **Solution**: Ensure at least one placeholder is positioned relative to bottom
- **Design**: Consider mountain height ranges when placing placeholders

### Very Short Mountains  
- **Issue**: All placeholders might be below screen when mountain spawns high
- **Solution**: Filter ensures only visible placeholders are selected
- **Fallback**: Skip nest placement if no valid positions

## Visual Feedback and Debugging

### Debug Mode Features
- **Placeholder Visualization**: Show all placeholders with different colors
- **Selection Highlighting**: Highlight selected placeholder
- **Visibility Indicators**: Show visibility calculation results
- **Screen Boundary Lines**: Display offset boundaries

### Production Logging
- Log selected placeholder position
- Track nest placement success/failure rates
- Monitor placeholder distribution usage

## Implementation Strategy

### Phase 1: Core System
1. Enhance `BaseObstacle` with multi-placeholder methods
2. Update `NestSpawner` selection logic
3. Add visibility filtering
4. Test with existing mountain scenes

### Phase 2: Scene Enhancement
1. Add multiple placeholders to floating island scenes
2. Balance placeholder positions for variety
3. Test placement with different obstacle heights

### Phase 3: Configuration and Polish
1. Add configuration parameters to stage system
2. Implement debug visualization
3. Balance visibility offsets per stage
4. Performance optimization

## Technical Implementation Notes

### Performance Considerations
- Placeholder detection happens once per obstacle spawn (low frequency)
- Array operations are minimal (2-6 placeholders max)
- No continuous calculations needed

### Backwards Compatibility
- Existing single-placeholder obstacles continue working
- `get_nest_placeholder()` method maintained for legacy support
- Gradual migration path for scene updates

### Testing Strategy
- Unit tests for visibility calculation
- Integration tests with different obstacle heights
- Visual tests with debug mode enabled
- Performance tests with many obstacles

## Prompt for Coding Agent

**High Level Task:** Implement a multi-placeholder nest placement system that ensures nests are always visible on screen when placed on mountains and floating islands.

**Conceptual Decision:** 
1. Extend BaseObstacle to support multiple NestPlaceholder nodes per obstacle
2. Add visibility filtering based on screen height and configurable bottom offset
3. Randomly select from visible placeholders when spawning nests
4. Maintain backwards compatibility with existing single-placeholder scenes
5. Add configuration parameters for fine-tuning placement behavior

**Key Technical Requirements:**
- Filter placeholders by `global_y < screen_height - offset`
- Handle obstacle scaling in position calculations  
- Gracefully skip nest placement if no visible placeholders
- Add debug mode for visualizing selection process
- Integrate with existing StageConfiguration system

**Scene Modifications Needed:**
- Enhance floating island scenes with 2-3 additional NestPlaceholder nodes
- Ensure placeholder positions provide good visual variety
- Test with different mountain heights and screen resolutions
