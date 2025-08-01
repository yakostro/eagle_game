
# Game concept. The Last Eagle

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

## Morale and energy
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

## Hit v1
- When eagle collides with the obstacle, it loses part of his energy
- Eagle is not interacting with the obstacles like a physical body
- Eagle blinks for a while and become immune to collisions for amount of time like in old-style games
- play animation 'hit' and then get back to the animation state that corresponds to eagle movement state. The blinking could last longer than 'hit' animation
- when eagle hit obstacle and has fish, 'drop fish' behavior  should be activated


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
- Placed on the right side of the screen outside the screen 
- Moves to the left with the speed of an eagle (use the same 'eagle/world speed' variable for all moving obstacles)
- At some obstacles could be spawn a nest

## Obstacle types:
- Mountain
- [Then will be added more...]

# Mountain
- When instantiated mountain should be placed at a random Y position: from SCREEN_HEIGHT-SPRITE_HEIGHT to SCREEN_HEIGHT-SPRITE_HEIGHT+offset. offset is a variable and == 500 px 


# Nest
## Instantiation
- Nest spawns once on every N (make a export var) obstacle
- nest placed inside the obstacle scene in the Marker2d 'NestPlaceholder'
- create nest spawner in the same file where all obstacles are being spawned

## States
- Hungry
- Fed

## Hungry state
- plays hungry animation
- If a nest collides with the fish:
	- It emits signal for eagle to increase moral points
	- Nest switched to Fed state
	- the sprite that is used in the fish is placed into the FishPlaceholder in the nest scene. preserve position, scale and rotation that fish sprite has before get into the nest

## Fed state
- plays fed animation


## Behavior (for any state)
- If nest goes off the left side of the screen, it emits a signal for the eagle to decrease moral points. Also the instance of the nest is deleted
- the world should be bigger than camera view and eagle shoul be able to move bot and top quite actively

