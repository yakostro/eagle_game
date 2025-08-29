# UI Message Queue System Design (Universal Label Approach)

## High-Level Concept

### Problem
The game currently has multiple UI feedback messages that can trigger simultaneously:
- "Nest ahead!" notification (1.5s duration)
- Morale popup container with "Chicks gonna die" + "-Morale" (1.2s duration)

These messages overlap and create visual chaos, reducing player experience quality.

### Solution
Implement a centralized message queue system with a **single universal message label** that:
- Uses one UI element for all message types
- Changes text content dynamically for different messages
- Displays messages sequentially with no overlap
- Adds a configurable delay (0.7s) between messages
- Vastly simplifies scene structure and maintenance

## Game Design Architecture

### Message Flow
```
Trigger Event → Queue Message → Process Queue → Show Universal Label → Change Text → Wait Duration → Add Delay → Next Message
```

### Message Types (Rich Text with Multi-Color Support)
- **NEST_INCOMING**: "[color=cyan]Nest ahead![/color]"
- **MORALE_NEGATIVE**: "[color=white]Chicks gonna die - [color=red]Morale lost![/color][/color]"
- **ENERGY_LOW**: "[color=orange]Energy [color=red]critical![/color][/color]"
- **FISH_NEARBY**: "[color=green]Fish spotted![/color]"
- **MIXED_EXAMPLE**: "[color=yellow]Found [color=cyan]3 Fish[/color] near [color=blue]Nest![/color][/color]"
- **Any future message**: Use BBCode color tags for rich formatting

### Timing System
- **Sequential Display**: Only one message visible at a time
- **Inter-message Delay**: 0.7 seconds between messages
- **Configurable Durations**: Different message types can have different display times
- **Queue Processing**: Continuous background processing

### User Experience Benefits
- **No Visual Conflicts**: Clean, professional message display
- **Improved Readability**: Player can process each message fully
- **Consistent Positioning**: All messages appear in same location
- **Unified Styling**: One label = consistent visual design
- **Easy Expansion**: Adding new messages requires zero scene changes

## Mechanics Impact

### Simplified Scene Structure
**Before**: Multiple UI elements (NestNotice, MoralePopContainer, etc.)
**After**: One `UniversalMessageRichLabel` (RichTextLabel) handles everything with multi-color support

### Balancing Parameters
- `inter_message_delay: float = 0.7` - Delay between messages (tweakable for pacing)
- `default_message_duration: float = 1.5` - Standard display time
- `message_durations: Dictionary` - Custom duration per message type

### Integration Points
- `queue_message(rich_text: String, duration: float = default_duration)` - Simple API with BBCode support
- Existing trigger events → Just call queue_message() with BBCode-formatted text
- Single NodePath: `universal_message_rich_label_path`

### Rich Text Formatting Examples
```gd
# Single color message
queue_message("[color=cyan]Nest ahead![/color]", 1.5)

# Multi-color message  
queue_message("[color=white]Chicks gonna die - [color=red]Morale lost![/color][/color]", 1.2)

# Complex formatting
queue_message("[color=yellow]Found [color=cyan]3 Fish[/color] near [color=blue]Nest![/color][/color]", 2.0)
```

---

## Coding Agent Prompt

**High-Level Task**: Implement a universal message queue system using a single RichTextLabel that displays rich text messages with multi-color support sequentially, preventing overlaps and ensuring expressive UI feedback.

**Conceptual Decision**: Replace multiple UI elements (NestNotice, MoralePopContainer) with one `UniversalMessageRichLabel` (RichTextLabel) that changes its BBCode-formatted text content dynamically. Use BBCode tags for multi-color text within individual messages.

**Key Requirements**:
1. **Single UI Element**: One RichTextLabel handles all message types with rich formatting
2. **Rich Text Queue**: Array of message objects with BBCode text and duration
3. **BBCode API**: `queue_message(rich_text: String, duration: float)` method supporting color tags
4. **Multi-Color Support**: Enable different colors for different words within same message
5. **State Management**: Track if system is busy showing a message
6. **Sequential Processing**: Process queue continuously, one message at a time
7. **Timing Control**: Universal timer for any message duration + inter-message delay (0.7s)

**Scene Structure Changes**:
- Replace existing NestNotice and MoralePopContainer with single `UniversalMessageRichLabel` (RichTextLabel node)
- Position RichTextLabel where you want all messages to appear
- Enable BBCode parsing in RichTextLabel inspector
- Style base font/size once for consistent appearance

**Technical Approach**:
- Extend existing `UIFeedback` class (don't create new files)
- Replace multiple NodePaths with single `universal_message_rich_label_path: NodePath`
- Rich text queue structure: `[{rich_text: String, duration: float}, ...]`
- Universal show/hide methods that work with BBCode-formatted text
- Use `rich_text_label.text = bbcode_string` to display formatted messages
- Convert existing triggers to use `queue_message()` calls with BBCode formatting

**BBCode Implementation**:
```gd
# Queue structure with rich text
var message_queue = [
    {rich_text: "[color=cyan]Nest ahead![/color]", duration: 1.5},
    {rich_text: "[color=white]Chicks gonna die - [color=red]Morale lost![/color][/color]", duration: 1.2}
]

# Display method applies BBCode text
func _show_message(message_data):
    universal_rich_label.text = message_data.rich_text
    universal_rich_label.visible = true
```

**Migration Strategy**:
- `_on_nest_incoming()` → `queue_message("[color=cyan]Nest ahead![/color]", 1.5)`
- `_on_nest_missed()` → `queue_message("[color=white]Chicks gonna die - [color=red]Morale lost![/color][/color]", 1.2)`
- Future messages: `queue_message("[color=yellow]Your [color=green]rich text[/color] here![/color]", duration)`

This approach is much simpler, more maintainable, and easier to expand with new message types.
