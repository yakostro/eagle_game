# Flexible Text Message Scene Design

## High-Level Concept

### Problem
The current MoralePopContainer is hardcoded for a specific two-label layout ("Nest missed" + "-Morale"). We need a flexible, reusable text message scene that can handle different message configurations while maintaining the existing UIMessage queue system and signal connections.

### Solution
Create a **flexible text message scene** that can dynamically configure itself for different display modes:
- **Single Text**: One centered label (e.g., "Nest ahead!")
- **Double Text**: Two labels side by side (e.g., "Nest missed" + "-Morale") 
- **Text + Icon**: Label with icon (e.g., "+20" with energy icon)

The scene will extend the existing UIMessage class to maintain all current signal connections and queue functionality.

## Game Design Architecture

### Scene Structure
```
FlexibleTextMessage (CanvasLayer)
├── MessageContainer (Control) - Center-anchored container
│   └── ContentLayout (HBoxContainer) - Dynamic content arrangement
│       ├── PrimaryLabel (Label) - Main text (always present)
│       ├── SecondaryLabel (Label) - Optional second text
│       └── MessageIcon (TextureRect) - Optional icon
└── Timer (Timer) - Message duration control
```

### Display Modes

#### Mode 1: Single Text (Center Aligned)
```
[    "Nest ahead!"    ]
```
- Uses: Nest incoming alerts, general notifications
- Configuration: Only PrimaryLabel visible
- Alignment: Center horizontal and vertical

#### Mode 2: Double Text (Side by Side)
```
[ "Nest missed"  "-Morale" ]
```
- Uses: Morale feedback, compound messages
- Configuration: Both PrimaryLabel and SecondaryLabel visible
- Alignment: Center with separation between labels
- Colors: Independent color control for each label

#### Mode 3: Text + Icon (Label with Visual)
```
[ "+20" [⚡] ] or [ [⚡] "+20" ]
```
- Uses: Energy feedback, item collection
- Configuration: PrimaryLabel + MessageIcon visible
- Alignment: Icon can be left or right of text
- Icon: Configurable texture and size

### Message Configuration System

#### Export Variables for Flexibility
```gdscript
# Display Mode Control
@export var message_mode: MessageMode = MessageMode.SINGLE_TEXT
enum MessageMode {
    SINGLE_TEXT,     # One centered label
    DOUBLE_TEXT,     # Two labels side by side  
    TEXT_WITH_ICON   # Label + icon
}

# Content Configuration
@export var primary_text: String = ""
@export var secondary_text: String = ""
@export var message_icon: Texture2D
@export var icon_position: IconPosition = IconPosition.RIGHT
enum IconPosition { LEFT, RIGHT }

# Visual Styling
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.RED
@export var font_size: int = 32
@export var label_separation: int = 20
@export var icon_size: Vector2 = Vector2(30, 30)

# Animation & Timing
@export var display_duration: float = 1.5
@export var fade_in_time: float = 0.2
@export var fade_out_time: float = 0.3
@export var enable_pulse_animation: bool = false
```

### Dynamic Layout System

#### Automatic Content Arrangement
The scene automatically configures its layout based on the selected mode:

1. **SINGLE_TEXT**: Hide secondary label and icon, center primary label
2. **DOUBLE_TEXT**: Show both labels, hide icon, arrange horizontally with separation
3. **TEXT_WITH_ICON**: Show primary label and icon, hide secondary label, arrange based on icon_position

#### Responsive Sizing
- Container auto-sizes to content
- Labels use size_flags for proper alignment
- Icon maintains aspect ratio with configurable size
- All elements center-aligned within screen bounds

### Integration with UIMessage System

#### Extending UIMessage Class
```gdscript
extends UIMessage
class_name FlexibleTextMessage
```

#### Message Type Mapping
```gdscript
# Extended message types for flexible display
enum FlexibleMessageType {
    NEST_INCOMING,      # Single text: "Nest ahead!"
    NEST_MISSED,        # Double text: "Nest missed" + "-Morale"  
    ENERGY_GAIN,        # Text + icon: "+20" + energy icon
    ENERGY_LOSS,        # Text + icon: "-15" + energy icon
    FISH_COLLECTED,     # Text + icon: "+Fish" + fish icon
    STAGE_COMPLETE,     # Single text: "Stage Complete!"
    ACHIEVEMENT         # Single text: "Achievement Unlocked!"
}
```

#### Signal Connection Preservation
- Maintains all existing signal connections from UIMessage
- Preserves nest_incoming, nest_missed, morale_changed connections
- Extends functionality without breaking existing game systems

## Scene Setup Architecture

### Node Structure Requirements
```
FlexibleTextMessage (CanvasLayer)
├── script: flexible_text_message.gd (extends UIMessage)
├── layer: 20 (UI overlay)
└── MessageContainer (Control)
    ├── anchors_preset: 8 (center)
    ├── grow_horizontal: 2 (both directions)
    └── ContentLayout (HBoxContainer)
        ├── alignment: 1 (center)
        ├── theme_override_constants/separation: 20
        ├── PrimaryLabel (Label)
        │   ├── layout_mode: 2
        │   ├── theme_override_fonts/font: Bangers-Regular.ttf
        │   ├── theme_override_font_sizes/font_size: 32
        │   ├── horizontal_alignment: 1 (center)
        │   └── vertical_alignment: 1 (center)
        ├── SecondaryLabel (Label)
        │   ├── layout_mode: 2
        │   ├── theme_override_fonts/font: Bangers-Regular.ttf
        │   ├── theme_override_font_sizes/font_size: 32
        │   ├── horizontal_alignment: 1 (center)
        │   ├── vertical_alignment: 1 (center)
        │   └── visible: false (initially hidden)
        └── MessageIcon (TextureRect)
            ├── layout_mode: 2
            ├── expand_mode: 1 (fit_width_proportional)
            ├── stretch_mode: 5 (keep_aspect_centered)
            └── visible: false (initially hidden)
```

### Animation System
- **Fade In**: Smooth alpha transition from 0 to 1 over fade_in_time
- **Display**: Full visibility for display_duration
- **Fade Out**: Smooth alpha transition from 1 to 0 over fade_out_time
- **Optional Pulse**: Subtle scale animation (1.0 to 1.05) for important messages

## Mechanics Impact

### Message Examples in Game Context

#### Nest System Messages
```gdscript
# Nest approaching
show_message(FlexibleMessageType.NEST_INCOMING, {
    "primary_text": "Nest ahead!",
    "primary_color": Color.CYAN
})

# Nest missed
show_message(FlexibleMessageType.NEST_MISSED, {
    "primary_text": "Nest missed",
    "secondary_text": "-Morale",
    "primary_color": Color.WHITE,
    "secondary_color": Color.RED
})
```

#### Energy System Messages
```gdscript
# Energy gained from fish
show_message(FlexibleMessageType.ENERGY_GAIN, {
    "primary_text": "+15",
    "icon_texture": energy_icon,
    "primary_color": Color.GREEN,
    "icon_position": IconPosition.RIGHT
})

# Energy lost from flapping
show_message(FlexibleMessageType.ENERGY_LOSS, {
    "primary_text": "-5",
    "icon_texture": energy_icon,
    "primary_color": Color.RED,
    "icon_position": IconPosition.RIGHT
})
```

### Balancing Parameters
All timing and visual parameters are exported for easy tweaking:
- Message durations for different types
- Animation speeds for smooth transitions
- Color schemes for different message categories
- Font sizes and spacing for readability
- Icon sizes and positioning for visual balance

### Backward Compatibility
- Replaces MoralePopContainer functionality seamlessly
- Maintains all existing UIMessage signal connections
- Preserves current message timing and queue behavior
- No changes required to existing game systems

## User Experience Benefits

### Visual Consistency
- Unified styling across all message types
- Consistent positioning and animation patterns
- Professional, polished appearance

### Flexibility for Future Content
- Easy to add new message types without scene changes
- Configurable for different game modes or difficulty levels
- Supports localization with dynamic text content

### Improved Readability
- Center-aligned messages for optimal visibility
- Appropriate spacing between text elements
- Clear visual hierarchy with color coding

---

## Coding Agent Prompt

**High-Level Task**: Create a flexible text message scene that replaces the hardcoded MoralePopContainer with a configurable system supporting single text, double text, and text+icon display modes, while extending the existing UIMessage class to maintain all signal connections and queue functionality.

**Conceptual Decision**: Build a single CanvasLayer scene with dynamic layout configuration that can adapt its content arrangement based on message type, using the existing UIMessage as a base class to preserve all current game system integrations.

**Key Requirements**:
1. **Scene Creation**: Create `scenes/ui/flexible_text_message.tscn` with CanvasLayer root
2. **Script Extension**: Create `scripts/ui/flexible_text_message.gd` extending UIMessage class
3. **Dynamic Layout**: HBoxContainer that shows/hides elements based on message mode
4. **Mode Support**: Three display modes (single text, double text, text+icon) with export enum
5. **Content Configuration**: Export variables for text, colors, icon, positioning
6. **Animation System**: Fade in/out animations with configurable timing
7. **Signal Preservation**: Maintain all existing UIMessage signal connections
8. **Message Type Extension**: Extend MessageType enum for new message categories

**Technical Approach**:
- Extend UIMessage class to inherit all existing functionality
- Use export enums for message mode and icon position configuration
- Implement dynamic show/hide logic for layout elements in _ready() and when messages change
- Create message configuration methods that set text, colors, and visibility
- Use existing Timer and Tween systems for animations
- Override UIMessage methods to use new flexible display system
- Export all visual and timing parameters for balancing

**Integration Points**:
- Replace MoralePopContainer usage in game.tscn with new FlexibleTextMessage scene
- Connect to same signals as current UIMessage (nest_incoming, nest_missed, etc.)
- Maintain existing message queue and timing system
- Support all current message types while enabling future expansion
- Preserve existing NodePath system for robust scene connections
