
# Game concept. The Last Eagle.

Aim: You play as the last eagle whose mission is to feed eagle chicks so the spieces can survive
Core gameplay: fly, evade obstacles, catch fish, feed chicks or eat, keep balance between morale and energy. The difficulty (obstacles, quantity of fish) raises through time
Lose: if morale or energy drops to 0
Score: count how many chicks survive

## Eagle:
- Flies through the terrain. Side view.
- Placed on the left side of the screen and controled by player (goes up / down)
- Has 'energy' and 'morale' atributes
- Spends energy overtime
- Losts morale points when pass through a nest without feeding
- The less morale points he has 
    - The faster he looses energy
    - Visually show depression (fading of the sides of the screen fex)

## Mechanics:
### Obstacles
- Rocks, mountain peaks and maybe trees that appears on the right side of the screen and moves to the left side with the speed of eagle 'movement'.
- Obstacles appears at the bottom and at the top
- The quantity and the difficulty of the obstacles are increasing over time
- If eagle collide with an obstacle, he dies. Energy and morale goes to 0.

### Catching fish
- Eagle catches a fish that is jumping from the bottom of the screen
- The eagle can eat this fish to get energy or keep fish to feed the chicks so they can survive
- To catch fish eagle has to:
- v1: be near the fish and catch it automatically


### Eating fish
- The eagle can eat cought fish to get energy

### Feeding
- Eagle can keep fish to feed the chicks so they can survive
- Chics appears in the nest on the top of mountain and move from right to left on the screen
- To feed chicks eagle has to drop a fish
- If eagle passes a nest without feeding its inhabitants he loses morale points


### Flying mechanics 1: casual 
- Energy loses overtime
- No control over flaping / gliding. User can freely move up and down
