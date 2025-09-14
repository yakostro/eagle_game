# Debug Keyboard Actions & Testing Controls

This document lists all available debug keyboard shortcuts and testing methods for the Eagle game development.



For reference, the normal gameplay controls are:
- **`W`**: Flap wings (move up)
- **`S`**: Dive (move down) 
- **`E`**: Eat fish
- **`Space`**: Drop fish (at nest)
- **`H`**: Screech

---

## Tips for Testing

- **`P` Key**: Quickly advance to the next stage to test different configurations
- **Stage Navigation (`1`–`6`)**: Jump directly to a specific stage (see detailed list below)
- **`Ctrl + R`**: Reset and start testing from the beginning
- **`Enter` Key**: Force obstacle spawns to test nest mechanics quickly
- **`I` Key**: Test Single Text mode ("Nest ahead!" in cyan)
- **`U` Key**: Test Double Text mode ("Nest missed" + "-Morale")
- **`O` Key**: Test Text + Icon mode ("+20" with energy icon)



## Stage System Debug Controls

These controls are handled by the **GameManager** and allow testing of the stage progression system:

