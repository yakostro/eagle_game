a 2d platformer where a pllayer controls an eagle
made with godot 4.2 and Godot script language

### States

## GLIDING 
- is a default state
- eagle scene plays 'glide' animation 
- time to time (make a constant, default 5 sec) eagle plays 'flap' animation once.
- eagle stays on the same altitude


## FLAPPING 
- when eagle goes up (rotation more than 7 degrees (use constant)) it begins use 'flap' animation




transitions between states are smooth 
