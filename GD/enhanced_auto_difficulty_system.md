# Enhanced Auto-Difficulty System

## High-Level Concept

The enhanced auto-difficulty system provides truly progressive late-game challenge by scaling ALL stage parameters, not just speed and distance. The system creates increasing tension through resource scarcity (fewer fish), environmental danger (taller obstacles), and feeding pressure (more frequent nests) while preserving the core fish boost mechanic that makes nests achievable.

## Key Mechanics

### Progressive Difficulty Tracks
- **Speed & Distance**: World moves faster, obstacles spawn closer together
- **Height Progression**: Mountains and stalactites become taller and more dangerous
- **Fish Scarcity**: Fish spawn less frequently between nests, creating resource tension
- **Nest Frequency**: More nests spawn, requiring more frequent feeding cycles
- **Obstacle Variety**: All obstacle types become more common over time

### Fish Boost Preservation
**CRITICAL**: The pre-nest fish boost system remains completely unchanged. Players still get:
- Guaranteed fish boost 2 obstacles before each nest
- 1.5s spawn interval during boost (vs increasingly longer base intervals)
- Minimum 2 fish guaranteed during boost period
- 8-second boost duration

This creates the intended difficulty curve: fish become scarce during exploration, but nests remain achievable through the boost system.

## Progression Timeline

### Early Auto-Difficulty (Levels 1-5, 0-75 seconds)
- **Focus**: Speed and distance scaling
- **Fish**: Minimal reduction (still plenty available)
- **Heights**: Slight increases (10-40% taller)
- **Nests**: Same frequency as Stage 6

### Mid Auto-Difficulty (Levels 6-10, 75-150 seconds)  
- **Focus**: Height progression and fish scarcity
- **Fish**: Noticeable reduction (20-40% less frequent)
- **Heights**: Significant increases (50-80% taller)
- **Nests**: Slightly more frequent

### Late Auto-Difficulty (Levels 11+, 150+ seconds)
- **Focus**: Maximum challenge across all parameters
- **Fish**: Major scarcity (50%+ less frequent, but boost still works)
- **Heights**: Maximum heights (60-80% increase capped)
- **Nests**: Very frequent (up to 2x more nests to feed)
- **Speed**: Near maximum (80% increase capped)

## Configuration Parameters

### Timing
- `progression_interval`: 15.0 seconds (balanced progression speed)

### Height Progression
- `mountain_height_increase_rate`: 8% per level (capped at 60% increase)
- `stalactite_height_increase_rate`: 12% per level (capped at 80% increase)

### Fish Scarcity
- `fish_availability_decrease_rate`: 6% per level (capped at 50% base availability)
- **Boost parameters remain constant** - this is the key to maintaining playability

### Nest Frequency  
- `nest_frequency_increase_rate`: 12% per level (capped at 2x frequency)
- Creates more feeding pressure without breaking the boost system

### Obstacle Variety
- All obstacle weights gradually increase, creating more varied patterns

## Implementation Benefits

1. **True Late-Game Challenge**: Every parameter scales, not just speed
2. **Preserved Core Mechanic**: Fish boost system ensures nests remain achievable
3. **Resource Management**: Fish scarcity creates strategic tension
4. **Environmental Danger**: Taller obstacles require better navigation skills
5. **Feeding Pressure**: More frequent nests test resource management
6. **Smooth Progression**: Gradual 15-second intervals prevent difficulty spikes

## Coding Agent Prompt

**High-Level Task**: The enhanced auto-difficulty system has been implemented with comprehensive parameter scaling.

**Decision**: The system uses a multi-track progression approach where different difficulty aspects (speed, height, fish scarcity, nest frequency) scale at different rates to create a balanced challenge curve. The fish boost system is intentionally preserved to maintain core gameplay while overall fish availability decreases.

**Next Steps for Coding Agent**:
1. Test the system in-game to validate progression feels smooth
2. Monitor debug output to ensure all parameters scale correctly  
3. Adjust balance values in `auto_difficulty_config.tres` if needed
4. Verify fish boost system works correctly with reduced base fish availability
5. Check that height progression doesn't make obstacles impossible to navigate

**Key Files Modified**:
- `scripts/systems/auto_difficulty_configuration.gd` - Added new parameters
- `scripts/systems/auto_difficulty_system.gd` - Enhanced progression logic
- `configs/auto_difficulty_config.tres` - Balanced default values

The system is ready for testing and fine-tuning based on gameplay feedback.
