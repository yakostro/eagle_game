# Fish Spawn Boost System Before Nest

## Problem Description
The player sometimes sees a nest, but no fish spawn during the time leading up to it. The objective becomes impossible to achieve — this is frustrating and breaks the basic "catch → feeding" cycle.

## Solution
A system for temporarily increasing fish spawn frequency before nest appearance has been implemented.

## System Parameters (all configurable in the inspector)

### In FishSpawner:
- `boost_enabled: bool = true` - Enable/disable boost system
- `boost_trigger_obstacles: int = 2` - How many obstacles before nest to start boost
- `boost_spawn_interval: float = 1.5` - Spawn interval during boost (faster than normal)
- `boost_duration: float = 8.0` - Boost duration in seconds
- `min_fish_guaranteed: int = 2` - Minimum guaranteed amount of fish during boost

## How It Works

1. **Linking with NestSpawner**: At startup, FishSpawner automatically finds NestSpawner and connects to the `nest_incoming` signal

2. **Boost Trigger**: When NestSpawner reports that `boost_trigger_obstacles` obstacles or fewer remain until nest, the boost is triggered

3. **Boost Activation**:
   - One fish spawns immediately for instant opportunity
   - Spawn interval decreases to `boost_spawn_interval`
   - Timer starts for `boost_duration` seconds
   - Count of fish spawned during boost is tracked

4. **Boost End**:
   - After time expires or maximum is reached
   - Minimum fish count is checked - if insufficient, additional fish are spawned
   - Spawn interval returns to normal

## Solution Benefits

- **Predictable**: System works according to clear rules
- **Non-intrusive**: No "spawn right in front", but guaranteed window of opportunity
- **Configurable**: All parameters adjustable in inspector
- **Reliable**: System guarantees minimum number of attempts

## Logging

System outputs informational messages:
- `🐟 FishSpawner: Connected to NestSpawner for pre-nest boost` - successful initialization
- `🐟 FISH BOOST STARTED! Interval: X.Xs for Y.Ys` - boost start
- `🐟 Fish boost ended. Spawned N fish during boost` - boost end
- `🐟 Spawning N additional fish to meet minimum guarantee` - additional spawn for guarantee

## Testing

To test the system:
1. Start the game
2. Wait for obstacles to appear
3. Watch for "Nest ahead!" message in UI
4. Before nest appears, more fish should spawn than usual
5. Check boost system logs in console