# Enhanced Eagle Death State System

## High-Level Concept

Transform the eagle's death from an instant game over into a dramatic falling sequence that emphasizes the tragic nature of the story. When the eagle runs out of energy, it loses the ability to flap and becomes subject to gravity, creating a melancholic descent that builds tension before the final game over transition.

## Game Design Rationale

### Story Enhancement
- **Emotional Impact**: The falling sequence reinforces the game's tragic theme - the last eagle's final moments fighting against gravity without energy to continue
- **Player Agency**: Players witness the consequences of their energy management decisions unfold gradually
- **Dramatic Tension**: The fall creates suspense - players watch helplessly as the eagle descends, knowing the inevitable outcome

### Gameplay Benefits
- **Natural Transition**: Eliminates jarring instant death, providing smooth progression from gameplay to game over
- **Visual Clarity**: Players clearly understand the cause-effect relationship between energy depletion and death
- **Last-Moment Hope**: Brief window where players might still learn from watching the physics play out

## Technical Architecture Overview

### Core Components Integration
1. **Movement Controller System**: Extend existing `BaseMovementController` architecture
2. **Eagle State Management**: Enhance current `is_dead` flag with intermediate dying state
3. **Physics System**: Leverage existing flappy bird gravity mechanics
4. **Animation System**: Integrate with existing `EagleAnimationController`
5. **Game Manager**: Modify death detection to watch for screen boundary instead of energy depletion

### Key Technical Decisions

#### Death State Phases
- **Phase 1 - Energy Depleted**: Eagle loses flapping ability but continues with existing physics
- **Phase 2 - Natural Fall**: Gravity takes over using existing flappy controller mechanics
- **Phase 3 - Screen Exit**: Trigger game over when eagle reaches bottom boundary

#### Input Blocking Approach
- **No New Controller**: Keep existing `FlappyMovementController`
- **Input Filtering**: Block flap input when `is_dying = true`
- **Natural Physics**: Let existing gravity and rotation systems handle the fall naturally

#### Screen Boundary Detection
- **Bottom Boundary**: Define screen bottom + margin as death trigger point
- **Camera-Relative**: Use existing camera system for consistent boundary detection
- **Safety Margin**: Include small buffer to ensure eagle is visually off-screen

## Detailed System Design

### 1. Eagle State Management Enhancement

#### Simple Death State Flag
- **Use Existing `is_dead`**: Rename to `is_dying` for clarity during fall phase
- **No New Movement States**: Keep existing `MovementState` enum unchanged
- **Input Filtering**: Block flap input in `FlappyMovementController` when dying

#### Dying State Characteristics
- **Input Blocking**: Flap input ignored when `is_dying = true`
- **Natural Physics**: Existing gravity and rotation systems handle fall automatically
- **No Energy Consumption**: Energy system becomes irrelevant in dying state
- **Collision Immunity**: Eagle passes through obstacles during fall

### 2. Flappy Movement Controller Modification

#### Input Handling Changes
- **Flap Input Check**: Add `is_dying` check before processing flap input
- **Existing Physics**: All gravity, velocity, and rotation mechanics remain identical
- **Natural Fall**: Eagle will naturally rotate downward due to existing rotation system
- **Seamless Transition**: No controller switching required

#### Animation Integration
- **Existing System**: Use current animation state system
- **Play Dying Animation**: Trigger `dying` animation immediately when entering dying state
- **No Flapping**: Animation controller receives no flap signals when dying
- **Natural Rotation**: Sprite rotation follows physics rotation as normal
- **Audio Cue**: Play a single screech sound once when energy reaches 0

### 3. Eagle Death State Management

#### State Variables
- **Single Flag**: Simple `is_dying` boolean to track death state
- **Optional Timer**: Minimum fall duration to prevent instant off-screen scenarios
- **Screen Position**: Monitor eagle's Y position relative to screen bottom

#### Energy System Modification
- **Death Trigger Change**: Energy depletion sets `is_dying = true` instead of immediate death
- **No Controller Switch**: Continue using existing movement controller
- **Input Blocking**: Prevent flapping through input filtering

### 4. Game Manager Integration

#### Death Detection Modification
- **Boundary Monitoring**: Instead of listening for immediate death, monitor eagle position
- **Game Over Trigger**: Call `_on_eagle_died()` when eagle exits screen bottom
- **Timing Control**: Optional delay before game over scene transition

#### Screen Boundary Definition
- **Bottom Boundary**: `screen_bottom + safety_margin`
- **Camera-Relative**: Use existing camera system for consistent positioning
- **Configurable Margin**: Allow adjustment of how far off-screen triggers game over

### 5. Animation Enhancement

#### Death Animation Sequence
- **Falling Pose**: Dedicated sprite frames for exhausted/falling eagle
- **Wing Position**: Wings partially extended but not flapping
- **Rotation Animation**: Smooth transition to downward-facing rotation

#### UX Feedback on Failed Flap
- **Instant Text Feedback**: When player attempts to flap while dying, show short message near eagle: `No [energy icon]`
- **Visual**: Use existing instant text feedback system and the standard energy icon from UI
- **Spam Control**: Use a small cooldown (e.g., 0.4–0.6s) to avoid message spam


## Implementation Parameters

### Configurable Variables
```gdscript
# Death State Timing
@export var min_death_fall_duration: float = 2.0  # Minimum fall time before game over
@export var death_boundary_margin: float = 100.0  # Pixels below screen to trigger game over

# Death Physics
@export var dying_gravity: float = 50.0  # Gravity during death fall (inherit from flappy controller)
@export var dying_max_velocity: float = 400.0  # Max fall speed when dying
@export var dying_rotation_speed: float = 1.0  # How fast eagle rotates to falling pose

# Death Animation
@export var death_animation_name: String = "dying"  # Animation to play when dying (exists in eagle.tscn)
@export var enable_death_particles: bool = false  # Optional visual effects

# Audio / Feedback
@export var play_screech_on_zero_energy: bool = true  # Play screech once when entering dying
@export var failed_flap_feedback_cooldown: float = 0.5  # Seconds between "No [energy icon]" messages
```

### Balance Considerations
- **Fall Duration**: Should feel dramatic but not tediously long (2-4 seconds typical)
- **Gravity Strength**: Match existing physics for consistency
- **Rotation Speed**: Natural-looking but not disorienting
- **Boundary Margin**: Enough to clearly show eagle has "fallen" but not excessive

## User Experience Flow

### Before Enhancement (Current)
1. Energy reaches 0
2. Instant death flag set
3. Immediate game over scene transition
4. Player may not understand what happened

### After Enhancement (Proposed)
1. Energy reaches 0
2. Eagle enters dying state - can no longer flap
3. Eagle falls under gravity with death animation
4. Player watches eagle's descent, understanding the consequence
5. Eagle exits screen bottom
6. Game over scene transition with clear cause-effect relationship

## Technical Implementation Benefits

### Leverages Existing Systems
- **Movement Controller**: Uses existing `FlappyMovementController` unchanged
- **Physics**: Identical gravity, velocity, and rotation behavior
- **Animation**: Natural falling animation through existing rotation system; explicit `dying` animation supported
- **Camera/Screen**: Uses established boundary detection methods

### Maintainable Design
- **Minimal Changes**: Only input filtering and game over timing modifications
- **Leverages Existing**: All physics, animation, and rotation systems unchanged
- **Simple Flag**: Single boolean state instead of complex state management
- **Reversible**: Easy to disable/modify with minimal risk to core systems

## Prompt for Coding Agent

**High-Level Task**: Implement an enhanced eagle death state system that creates a dramatic falling sequence when the eagle runs out of energy, replacing the current instant death with a gravity-driven descent that ends when the eagle reaches the bottom of the screen.

**Implementation Decision**: 
1. Add `is_dying` flag to eagle state management
2. Modify `FlappyMovementController` to ignore flap input when eagle is dying
3. Modify the eagle's `die()` method to enter dying state instead of immediate death
4. Change game over trigger from energy depletion to screen boundary detection
5. Let existing physics and animation systems handle the fall naturally

**Key Requirements**:
- Keep existing `FlappyMovementController` unchanged except for input filtering
- Use existing physics values (gravity, velocity limits, rotation) without modification
- Maintain camera-relative screen boundary detection
- Block only flap input when dying, let natural physics handle the fall
- Provide configurable screen boundary margin for easy balancing
- Rely on existing animation system; play `dying` animation and stop flap animations
- Play a single screech audio cue on entering dying
- On attempted flap while dying, show instant text: `No [energy icon]` with cooldown

**Success Criteria**: 
- Eagle cannot flap when energy reaches 0 but continues with natural physics
- Game over triggers only when eagle exits bottom of screen
- Eagle naturally rotates downward due to existing rotation system
- `dying` animation plays immediately and persists during the fall
- A screech sound plays once when energy hits 0
- Attempted flaps while dying show `No [energy icon]` feedback (rate-limited)
- All existing gameplay mechanics remain functional until energy depletion
- Minimal code changes - primarily input filtering, animation/audio trigger, and game over timing

## Developer Tasks (Step-by-step)

1) Add dying state flag and timing
- Add `is_dying` boolean to eagle and optional `min_death_fall_duration`
- On energy <= 0, set `is_dying = true` (only once), start optional fall timer

2) Trigger animation and audio on entering dying
- Immediately play `dying` animation via `EagleAnimationController`
- Play a single screech sound (guard against repeats)

3) Block flapping while dying
- In `FlappyMovementController`, ignore flap input when eagle `is_dying`
- Ensure movement physics and rotation continue unchanged

4) Show instant feedback on attempted flap
- When player tries to flap while dying, call Instant Text Feedback to show `No [energy icon]`
- Add a small cooldown between messages (`failed_flap_feedback_cooldown`)

5) Postpone game over until off-screen bottom
- Monitor eagle position relative to camera/view; when below bottom + margin, trigger game over
- Respect `min_death_fall_duration` if enabled

6) Inspector parameters and wiring
- Expose: `death_animation_name`, `play_screech_on_zero_energy`, `failed_flap_feedback_cooldown`, `death_boundary_margin`, `min_death_fall_duration`
- Ensure `EagleAnimationController` has a `dying` track bound in `eagle.tscn`

7) Test pass
- Cases: normal play; deplete energy mid-air; attempted spam flaps while dying; boundary-based game over
- Verify audio plays once, animation persists, and feedback throttles
