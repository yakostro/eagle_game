
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
- Player presses SPACE to release a fish

## Eat fish
- When player press E button on the keyboard AND an eagle has a fish, an eagle eats a fish
- Make a signal for this event so fish could disappear and UI animation about adding energy could be played
- Add energy (from fish’s parameter) to the eagle

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
- Add Morale points to the eagle

## Eaten
- Fish disappears from the claws 
- Add an energy to the eagle

Obstacles:
## Instantiation
- Make one spawner for all obstacles (fish is not an obstacle)
- Obstacle spawns once in a while (make export var)
- Placed on the right side of the screen outside the screen and 
- Moves to the left with the speed of an eagle (use the same 'eagle/world speed' variable for all moving obstacles)
- At some obstacles could be spawn a nest

## Obstacle types:
- Mountain
- [Then will be added more...]

# Mountain
- When instantiated mountain have to be scaled from 0.5 to 1.5 on Y axis of its size
- The lowest edge of the mountain should always be on the edge of the screen (it is a zero )


# Nest
## Instantiation
- Nest spawns once on every N (make a export var) obstacle
- nest placed on the top of the obstacle sprite with 20 px offset down

## Nest scene configuration
- Nest scene is consist of two main parts: NEST and a BASIS. Basis is a MOUNTAIN. 
- A nest and a mountain are separate sprites
- when spawned, mountain sprite should be scaled from 0.5 to 1.5 (make export vars)
- the nest sprite should always be on top

## Behavior
- If a nest collides with the fish, it emits signal for eagle to increase moral points
- If nest goes off the left side of the screen, it emits a signal for the eagle to decrease moral points. Also the instance of the nest is deleted
- the world should be bigger than camera view and eagle shoul be able to move bot and top quite actively

