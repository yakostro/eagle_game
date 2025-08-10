
# Game concept. The Last Eagle

# Story and world
## Story:

there is a postapocalyptic world and a lot of species are about to extinct. there are the last adult eagle left and a lot of abandoned nests with hungry eagle chicks. The only mission of this exhausted bald eagle is to feed this chicks and hope that the specie will survive even at a price of it’s own life

## Mood and feel:
- Grim mood
- ‘Morale’ parameter is a key. Player has to realize how BAD actually the missing nest is. It’s a key.
	- We should show it super explicitly to user and the influence should be visible and feelable.
	- When the nest appear. Show user that nest is important.


*Aim*: You play as the last eagle whose mission is to feed eagle chicks so the species can survive
Core gameplay: fly, evade obstacles, catch fish, feed chicks to get morale or eat fish to get energy, keep balance between morale and energy. The difficulty (obstacles, quantity of fish) raises through time
Lose: if energy drops to 0
Score: count how many chicks survived
Eagle Flies through the terrain. Side view.
Eagle is controlled by the player


Detailed description
# Eagle
## Eagle movement and controls
- Eagle can move UP an DOWN
	- To move Up: W and UP_ARROW
	- To move Down: S and DOWN ARROW
- No gravity applied to the eagle

## States
- IDLE
- CHANGING_POSITION
- HIT
- SCREECH
- DIE

Parameters:
has_fish


## Catch fish
- When eagle collides with fish and has no fish in claws, he catches it
- If caught, fish sit in the claws of the eagle. It rotates with the eagle rotation
- Eagle can carry only one fish at a time
- if eagle already has a fish and fish collides with the eagle, then fish is just continue moving 

## Release fish
- If eagle has fish in his claws he can release it
- Player presses F to release a fish

## Eat fish
- When player press E button on the keyboard AND an eagle has a fish, an eagle eats a fish
- Make a signal for this event so fish could disappear and UI animation about adding energy could be played
- Add energy (from fish’s parameter) to the eagle

## Hit
- When eagle collides with the obstacle, it loses part of his energy
- Eagle is not interacting with the obstacles like a physical body
- Eagle blinks for a while and become immune to collisions for amount of time like in old-style games
- play animation 'hit' and then get back to the animation state that corresponds to eagle movement state. The blinking could last longer than 'hit' animation
- when eagle hit obstacle and has fish, 'drop fish' behavior  should be activated
- when the eagle is hit by enemy bird it looses energy corresponding to the value defined in the bird script (default 20 energy points)


# Morale and energy
Energy
- Energy loses overtime
- Make a energy_lose_points variable how much it lose in a sec
- Energy_lose_points increased if the morale points goes down, so the less the morale is the faster an eagle lose his energy
- When an eagle eats a fish - fish energy is added to the current energy. Energy defined in a particular fish
- When an eagle hit an obstacle (tree, mountain, island, bullet etc), he losses amount of energy (defined by the obstacle)
- When energy is 0, eagle dies

Morale
- When a NEST goes off screen without being fed, an eagle lose morale points
- Morale can't go below 0
- If morale is 0 eagle can still fly


# Fish
## Instantiation
- Fish spawns on the right from the eagle below the bottom of the screen
- Fish jumps to the left towards eagle
- Each fish jumps with slightly different velocity and angle
- Gravity is applied to a fish
- Fish has an energy const. It will be added to the eagle energy when eaten

## Caught
- Fish sits in the claws
- No gravity or collision applied to fish

## Released
- Fish starts to fall down with gravity applied
- If it goes below the screen - delete an instance

## Fed
- If fish collides with a NEST it disappears
- Add signal for UI to play positive feedback animation

## Eaten
- Fish disappears from the claws 
- Add an energy to the eagle

Obstacles:
## Instantiation
- Make one spawner for all obstacles (fish is not an obstacle)
- Obstacle spawns once in a while (make export var)
- there are several types of obstacles
- the spawner chose what type of obstacle will be placed
- Placed on the right side of the screen outside the screen 
- Moves to the left with the speed of an eagle (use the same 'eagle/world speed' variable for all moving obstacles)
- At some obstacles could be spawn a nest
- Nest could be spawn on the obstacles where the 'NestPlaceholder' is. Maybe it's worth to add a parameter determining is nest could be placed for the obstacle

## Obstacle types:
- Mountain
- Stalactite
- Floating Island
- [Then will be added more...]

# Mountain
- When instantiated mountain should be placed at a random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset. offset is a variable and == 500 px 

# Stalactite
- When instantiated stalactite should be placed at a random Y position: from -sprite_height + minimum_stalactite_height to 0
- the nest could not be placed at the stalactite

# Floating Island
- When instantiated stalactite should be placed at a random Y position: from minimum_top_offset = 500 to minimum_bottom_offset + sprite_height. minimum_bottom_offset = 300

# Nest
## Instantiation
- Nest spawns once on every N (make a export var) obstacle
- nest placed inside the obstacle scene in the Marker2d 'NestPlaceholder'
- Spawn at random mountain within min and max interval. 
- Increase difficulty > more rare nest spawn.

## States
- Hungry
- Fed

## Hungry state
- plays hungry animation
- If a nest collides with the fish:
	- It emits signal for eagle to increase moral points
	- Nest switched to Fed state
	- the sprite that is used in the fish is placed into the FishPlaceholder in the nest scene. preserve position, scale and rotation that fish sprite has before get into the nest
	- fish should be fed to nest ONLY if it was dropped from the eagle. otherwise it shouldn't be fed

## Fed state
- plays fed animation


## Behavior (for any state)
- If nest goes off the left side of the screen, it emits a signal for the eagle to decrease moral points. Also the instance of the nest is deleted
- the world should be bigger than camera view and eagle shoul be able to move bot and top quite actively

Enemies:
- make a enemies spawner that will control spawn of different enemy types.

# Enemy types:
- enemy bird

# Enemy bird
## Instantiate
- enemy bird is spawned on the right side of the screen
- it spawned once in a while (make a var)
- should be progression in difficulty 

## Movement
- when spawned enemy bird moves towards the eagle Y position by curve and tries to hit an eagle.
- bird moves with the acceleration
- if the eagle change its position, enemy bird tries to make it’s new trajectory towards his new Y position but it has a limitation - the speed of change direction (make a ver)
- birds fly through the eagle and not stop on the eagle's X coordinate, they just continue moving towarsds left edge of the screen.
- if an enemy bird hit the eagle it continue move with the same direction as it moved before and goes off the screen on a left side
- When bird's X more than eagle's X - bird shouldnt consider eagle's change position 
at all
- birds must not collide and interact with the eagle, just check for collision

## Misc
- I have EnemyBird.tscn character body 2d with a sprite and collision capsule
- when  enemy bird goes off screen it is  removed from the game


# Art Direction
## Limited Color Palette System
- The entire game uses a limited color palette enforced through a global post-processing shader
- Uses DawnBringer 16 (DB16) palette by default: 16 carefully chosen colors that work well together
- Palette is applied via screen-space shader that:
  - Remaps all rendered colors to the nearest palette color
  - Uses ordered dithering (4x4 Bayer matrix) to reduce color banding
  - Processes game world but excludes UI (UI rendered in higher CanvasLayer)
- Configurable parameters:
  - `palette_size`: Number of colors in palette (1-64)
  - `use_dither`: Enable/disable dithering effect
  - `dither_strength`: Intensity of dithering pattern
  - `saturation`, `contrast`, `brightness`: Color adjustments before palette mapping
- Benefits:
  - Unified art style across all sprites and backgrounds
  - Retro/pixel art aesthetic without requiring pixel-perfect artwork
  - Easy to experiment with different color schemes
  - Performance-friendly single-pass effect

Sounds
# ambient
- I have embient sound node in the game scene.
- And two wind sounds. I want to intermix them.
- wind_woosh_loop.ogg should be the basic.
- additional_wind.wav should be mixed time to time. different parts of it like a span from 5 to 8 sec. and the next time - another part of this audio. with fade. 
