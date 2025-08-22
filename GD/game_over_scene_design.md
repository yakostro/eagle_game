# Game Over Scene Design Document

## Overview
The Game Over Scene serves as the conclusion point for The Last Eagle gameplay, celebrating player achievements while providing smooth transition back to new gameplay sessions.

## Design Goals

### Primary Objectives
- **Achievement Recognition**: Prominently display number of nests saved during the session
- **Emotional Closure**: Provide satisfying conclusion to the eagle's journey
- **Replayability**: Encourage immediate restart with minimal friction
- **Consistency**: Maintain visual and atmospheric coherence with main game

### User Experience Principles
- **Clear Visual Hierarchy**: Game Over → Stats → Action Button
- **Immediate Comprehension**: Player instantly understands their performance
- **Single-Click Restart**: Minimal barriers to starting new session
- **Atmospheric Continuity**: Preserve game's majestic eagle theme

## Scene Architecture

### Visual Structure
```
GameOverScene (Control - Full Screen)
├── BackgroundLayer (CanvasLayer -10)
│   └── BackgroundImage (atmospheric backdrop)
├── UILayer (CanvasLayer 10)
│   └── UIContainer (Control)
│       ├── GameOverLabel (Large title typography)
│       ├── StatsContainer (VBoxContainer - center focus)
│       │   ├── SavedNestsLabel ("Saved N Nests")
│       │   └── [Future expansion: time survived, fish caught]
│       └── RestartButton (prominent call-to-action)
└── AudioController (ambient sounds/music)
```

### Layout Design Decisions
- **Centered Composition**: All elements focus player attention on achievement
- **Vertical Flow**: Natural reading pattern from title → stats → action
- **Generous Spacing**: Elegant presentation befitting the eagle's majesty
- **Scalable Container**: Future-ready for additional statistics

## Game Statistics System

### Data Tracking Architecture
**Problem**: Godot scenes are isolated - game statistics don't persist between scene changes

**Solution**: Global singleton pattern for statistics persistence
- **GameStats singleton** (AutoLoad) maintains data across scenes
- **Thread-safe access** for real-time updates during gameplay
- **Reset functionality** for fresh game sessions

### Core Metrics
- **Fed Nests Count**: Primary achievement metric - number of successfully fed nests
- **Session Duration** (future): Total gameplay time
- **Fish Collected** (future): Total fish caught during session
- **Obstacles Survived** (future): Challenge progression indicator

### Data Flow
```
Gameplay: Nest.nest_fed → GameManager.on_nest_fed() → GameStats.increment_fed_nests()
Game End: Eagle.eagle_died → GameManager.trigger_game_over() → SceneManager.change_to_game_over()
Display: GameOverScene._ready() → GameStats.get_fed_nests_count() → UI Update
Restart: RestartButton.pressed → GameStats.reset_session() → SceneManager.change_to_game()
```

## Technical Implementation Requirements

### Scene Components
1. **game_over_scene.tscn**: UI scene structure with proper anchoring
2. **game_over_scene.gd**: Scene controller handling initialization and interactions
3. **game_stats.gd**: AutoLoad singleton for persistent data management
4. **GameManager enhancements**: Integration with statistics tracking
5. **Eagle death trigger**: Proper game over activation

### Integration Points
- **GameManager**: Track nest feeding events via existing signal connections
- **SceneManager**: Utilize existing fade transition system for smooth experience
- **Eagle**: Connect death event to game over trigger
- **Nest**: Ensure fed events properly increment statistics

### Input Handling
- **Primary Action**: Restart button click → immediate game restart
- **Keyboard Support**: Space/Enter for accessibility and speed
- **Future Enhancement**: Escape key → return to main menu

## Visual Design Specifications

### Typography Hierarchy
- **Game Over**: Large, bold text (48-64px) - dominant presence
- **Saved Nests**: Medium text (24-32px) - achievement celebration
- **Button Text**: Clear, readable (20-24px) - action clarity

### Color Palette
- **Background**: Atmospheric blues/grays matching game's sky theme
- **Text**: High contrast whites/yellows for readability
- **Button**: Distinct color (golden/orange) drawing attention to action
- **Accent**: Subtle highlights celebrating achievement

### Layout Proportions
- **Top Third**: Game Over title with breathing room
- **Middle Third**: Statistics display - focal point
- **Bottom Third**: Restart button with adequate touch targets

## Sound Design Integration

### Audio Elements
- **Ambient Background**: Gentle wind sounds maintaining atmospheric continuity
- **Achievement Sound**: Subtle positive audio feedback for nest count reveal
- **Button Interaction**: Clear audio feedback for restart action
- **Transition Audio**: Seamless integration with SceneManager fade system

## Future Enhancement Opportunities

### Statistics Expansion
- **Performance Grades**: S/A/B/C ranking based on nests saved vs. missed
- **Leaderboard Integration**: Local high scores for saved nests
- **Achievement Unlocks**: Milestone celebrations (10 nests, 25 nests, etc.)
- **Session Analytics**: Detailed breakdown of gameplay performance

### Visual Enhancements
- **Animation Polish**: Smooth number counting animation for nest display
- **Particle Effects**: Subtle celebratory effects for high achievements
- **Dynamic Backgrounds**: Different backdrops based on performance level
- **Eagle Memorial**: Artistic representation of the eagle's final moments

---

## Coding Agent Prompt

### High-Level Task
Create a polished Game Over Scene that displays the number of nests saved during gameplay and provides immediate restart functionality.

### Implementation Decisions
1. **Use GameStats singleton pattern** for persistent data storage across scenes
2. **Leverage existing SceneManager** fade transition system for smooth experience  
3. **Integrate with current GameManager** nest tracking via signal connections
4. **Follow established UI patterns** from start_scene.tscn for consistency
5. **Connect Eagle death event** to trigger game over transition
6. **Implement single-click restart** that resets statistics and loads fresh game scene

### Technical Requirements
- game_stats.gd AutoLoad singleton with fed_nests_count tracking
- game_over_scene.tscn with proper Control node hierarchy and responsive layout
- game_over_scene.gd script handling initialization, display, and restart actions
- GameManager.gd updates to track nest feeding and trigger game over
- Eagle.gd death event integration with scene transition
- Maintain existing code style with export variables for tweakable parameters

### Success Criteria
- Player sees "Game Over" and "Saved N Nests" immediately upon eagle death
- Restart button immediately loads fresh game.tscn with reset statistics
- Visual hierarchy clearly communicates achievement and next action
- Seamless integration with existing scene management and audio systems
