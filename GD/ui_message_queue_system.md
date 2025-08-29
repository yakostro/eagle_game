# UI Message Queue System Design

## High-Level Concept

### Problem
The game currently has multiple UI feedback messages that can trigger simultaneously:
- "Nest ahead!" notification (1.5s duration)
- Morale popup container with "Chicks gonna die" + "-Morale" (1.2s duration)

These messages overlap and create visual chaos, reducing player experience quality.

### Solution
Implement a centralized message queue system within the existing `UIFeedback` class that:
- Queues all UI messages instead of showing them immediately
- Displays messages sequentially with no overlap
- Adds a configurable delay (0.7s) between messages
- Maintains existing visual elements and functionality

## Game Design Architecture

### Message Flow
```
Trigger Event → Queue Message → Process Queue → Show Message → Wait Duration → Add Delay → Next Message
```

### Message Types
- **NEST_INCOMING**: "Nest ahead!" notification using existing NestNotice label
- **MORALE_NEGATIVE**: Morale feedback using existing MoralePopContainer

### Timing System
- **Sequential Display**: Only one message visible at a time
- **Inter-message Delay**: 0.7 seconds between messages
- **Preserved Durations**: Keep existing 1.5s for nest, 1.2s for morale
- **Queue Processing**: Continuous background processing

### User Experience Benefits
- **No Visual Conflicts**: Clean, professional message display
- **Improved Readability**: Player can process each message fully
- **Consistent Timing**: Predictable message rhythm
- **Preserved Functionality**: All existing triggers work unchanged

## Mechanics Impact

### Balancing Parameters
- `inter_message_delay: float = 0.7` - Delay between messages (tweakable for pacing)
- `nest_notice_duration: float = 1.5` - Existing nest message duration
- `morale_pop_duration: float = 1.2` - Existing morale message duration

### Integration Points
- Existing `_on_nest_incoming()` method → Queue nest message
- Existing `_on_nest_missed()` method → Queue morale message  
- Same NodePath system for UI elements
- No scene structure changes required

---

## Coding Agent Prompt

**High-Level Task**: Implement a message queue system in the existing `UIFeedback` class to prevent overlapping UI messages and ensure sequential display with delays.

**Conceptual Decision**: Create a centralized queue manager that processes UI messages one at a time, using the existing UI elements but controlling their display timing through a state machine approach.

**Key Requirements**:
1. **Message Queue Structure**: Array-based queue with message type enum and data
2. **State Management**: Track if system is busy showing a message
3. **Sequential Processing**: Process queue continuously, one message at a time
4. **Timing Control**: Use existing timer system, add inter-message delay of 0.7s
5. **Backward Compatibility**: Existing trigger methods should queue messages instead of showing directly
6. **Export Variables**: Make inter-message delay tweakable in inspector

**Technical Approach**:
- Extend existing `UIFeedback` class (don't create new files)
- Use existing `_nest_timer` pattern but make it universal for all messages
- Preserve all existing NodePath and visual functionality
- Add message queue processing in `_ready()` or with signal-based approach
- Ensure smooth transitions between different message types

**Integration**: Update `_on_nest_incoming()` and `_on_nest_missed()` to add messages to queue instead of showing immediately, while keeping all existing visual elements and durations unchanged.
