# Unified Energy/Morale UI System Design

## High-Level Concept

Create a unified progress bar system where energy and morale are visualized on the same scale, making the relationship between these resources immediately clear to the player. This replaces the traditional dual-bar approach with a more intuitive single-bar system where morale directly affects energy capacity.

## Core Mechanics

### Visual Representation
- **Single horizontal progress bar** positioned at the top-center of the screen
- **Lightning icon** on the left side of the bar to clearly indicate this is energy
- **Three-state color system**:
  - **Yellow**: Available energy (current energy level)
  - **White**: Energy being lost (temporary visual feedback)
  - **Gray**: Morale-locked capacity (unavailable energy space)

### Energy Behavior
- Starts at 100% capacity (full yellow bar)
- When energy decreases:
  1. Show decreasing amount in **white** for a brief period (visual feedback)
  2. Then remove the white portion from the bar
- Energy fills/drains from left to right within available capacity

### Morale Integration
- When eagle loses morale:
  - **Gray sections** appear from the RIGHT side of the bar
  - Gray represents "locked" energy capacity
  - Available energy space shrinks accordingly
- When eagle gains morale:
  - Gray sections shrink from the right
  - Available energy capacity increases
  - **Important**: Energy itself is NOT added, only capacity increases

### Visual States Examples
```
100% Energy, 100% Morale: [████████████████████] (full yellow)
80% Energy, 100% Morale:  [████████████░░░░░░░░] (yellow + empty)
80% Energy, 60% Morale:   [████████████░░██████] (yellow + empty + red pattern)
40% Energy, 60% Morale:   [████████░░░░██████]     (yellow fits in available space)
```

## Architecture Requirements

### Scene Structure
```
EnergyMoraleUI (Control Node)
├── Container (HBoxContainer)
│   ├── EnergyIcon (TextureRect) - Lightning symbol
│   └── ProgressBarContainer (Control)
│       └── EnergyProgressBar (Custom ProgressBar)
│           ├── EnergyFill (TextureProgress) - Yellow energy
│           ├── EnergyLossFeedback (TextureProgress) - White feedback
│           └── MoraleLock (TextureProgress) - red pattern locked area
```

### Script Architecture
- **EnergyMoraleUI**: Main UI controller
- **Custom ProgressBar**: Handles the three-layer visualization
- **Energy/Morale Manager**: Data management (separate from UI)

### Inspector Configuration
- **Energy Colors**: Yellow (full), white (feedback), gray (locked)
- **Feedback Duration**: How long white energy loss is shown
- **Bar Dimensions**: Width, height, positioning
- **Icon Configuration**: Lightning icon texture and size

## Game Design Benefits

### Player Experience
1. **Immediate Clarity**: Player instantly sees how morale affects their energy capacity
2. **Emotional Impact**: Losing morale feels like losing part of yourself (literal capacity loss)
3. **Strategic Depth**: Players must balance risking energy vs. maintaining morale
4. **Visual Feedback**: Energy changes are clearly communicated through color transitions

### Mechanical Integration
- Reinforces the core narrative: low morale makes the eagle less capable
- Creates tension: low morale means less energy buffer for risky maneuvers
- Emphasizes nest-feeding importance: morale directly impacts survival capacity

## Technical Considerations

### Performance
- Use efficient texture-based progress bars
- Pool temporary white feedback effects
- Update UI only when values change

### Responsiveness
- Smooth transitions between states
- Clear visual hierarchy (energy icon → bar → feedback)
- Accessible color choices (consider colorblind players)

---

## Implementation Tasks

### Task 1: Create UI System
**Goal**: Build the visual energy/morale progress bar system

**Approach**: 
- Create custom progress bar component with three-layer rendering
- Position at top-center with lightning icon
- Implement smooth color transitions and feedback effects
- Configure inspector properties for easy tweaking

**Key Components**:
- EnergyMoraleUI scene with proper CanvasLayer (layer 10 to avoid palette shader)
- Custom progress bar with three texture overlays
- Animation system for energy loss feedback (white flash)
- Inspector-configurable colors and timing

### Task 2: Integrate Game Logic
**Goal**: Connect existing energy/morale systems to the new UI

**Approach**:
- Modify existing energy/morale scripts to work with capacity system
- Create signals for UI updates
- Implement morale-affects-capacity logic
- Ensure smooth integration with existing game mechanics

**Key Changes**:
- Update energy system to respect morale-based maximum capacity
- Create UI update signals from game manager
- Implement energy loss feedback timing
- Test integration with fish eating and nest feeding systems
