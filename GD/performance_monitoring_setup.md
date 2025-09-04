# Performance Monitoring Setup Guide

## Quick Setup (5 minutes)

### Step 1: Add Performance Monitor to Your Game Scene

1. Open your main game scene (`scenes/game_stages/game.tscn`)
2. Add a new Node (right-click → Add Child Node → Node)
3. Name it "PerformanceMonitor"
4. Attach the script: `scripts/performance_monitor.gd`
5. Configure the settings in the Inspector:
   - Monitor Interval: 1.0 (seconds)
   - Show FPS: ON
   - Show Memory: ON
   - FPS Warning Threshold: 30
   - Memory Warning Threshold: 500 (MB)

### Step 2: Add Performance Profiler (Optional)

1. Add another Node named "PerformanceProfiler"
2. Attach the script: `scripts/performance_profiler.gd`
3. Set the paths in Inspector:
   - Obstacle Spawner Path: `../ObstacleSpawner`
   - Game Manager Path: `../GameManager`

### Step 3: Test the Setup

1. Run the game normally
2. Watch the console for performance statistics
3. Performance data will print every second

## Using the Performance Tools

### FPS Counter (Always Available)
- **Top Right Corner**: Real-time FPS display with frame time
- **Color Coding**:
  - **White**: Good performance (30+ FPS)
  - **Red**: Warning (15-30 FPS)
  - **Dark Red**: Critical (< 15 FPS)
- **Toggle**: Press **F12** to show/hide FPS counter

### In-Game Debug Keys
- **F1**: Print current performance stats
- **F2**: Print detailed performance report
- **F3**: Reset performance statistics

### From Godot Editor Console
```gdscript
# Get performance monitor reference
var monitor = get_node("/root/Game/PerformanceMonitor")

# Print detailed report
monitor.get_performance_report()

# Reset stats
monitor.reset_stats()
```

## Performance Monitoring Checklist

### CPU/GPU/Memory Usage
- [ ] Run with `--print-fps` flag
- [ ] Monitor console output for FPS drops
- [ ] Check memory usage in Task Manager
- [ ] Watch GPU usage in Task Manager

### Identifying Performance Bottlenecks

#### In Your Code:
1. **Obstacle Spawning**: Check `ObstacleSpawner._process()` - too many spawns?
2. **Physics**: Many collision shapes? Consider simplifying.
3. **Rendering**: Too many sprites? Use texture atlasing.
4. **Scripts**: Heavy `_process()` functions? Move to `_physics_process()` or optimize.

#### Common Issues in Your Game:
1. **Obstacle Count**: Your game spawns many obstacles - monitor for cleanup
2. **Physics Objects**: Many moving obstacles may cause physics lag
3. **Stage Transitions**: Loading new stages may cause frame drops
4. **Particle Effects**: Wind particles may impact performance

### Optimization Tips for Your Game

#### Immediate Improvements:
1. **Object Pooling**: Reuse obstacle instances instead of creating/destroying
2. **Distance Culling**: Don't process obstacles far off-screen
3. **Simplify Collisions**: Use simpler collision shapes for distant objects
4. **Batch Rendering**: Group similar sprites together

#### Monitor These Specific Areas:
1. **ObstacleSpawner._process()**: Distance-based spawning logic
2. **BaseObstacle._physics_process()**: Movement and collision detection
3. **ParallaxBackground**: Multiple layer updates
4. **StageManager**: Configuration loading and transitions

### Advanced Profiling

#### Using External Tools:
1. **Windows Task Manager**: CPU, GPU, Memory tabs
2. **GPU Monitoring**: NVIDIA Control Panel or AMD Software
3. **Godot Profiler**: Editor → Debugger → Profiler tab

#### Godot-Specific Commands:
```bash
# Basic performance monitoring
godot --print-fps --gpu-profile

# Debug physics
godot --debug-collisions

# Profile scripts
godot --profiling
```

## Troubleshooting Performance Issues

### If FPS drops below 30:
1. Check obstacle count (should be <50 active)
2. Monitor physics objects (should be <100)
3. Reduce spawn rate in later stages
4. Simplify collision shapes

### If memory usage is high (>500MB):
1. Check for object leaks (obstacles not being cleaned up)
2. Monitor texture memory usage
3. Consider unloading unused assets
4. Use object pooling for frequently spawned objects

### If GPU usage is high:
1. Check draw call count (should be <100)
2. Monitor vertex count (should be <50k)
3. Consider reducing sprite resolution
4. Use fewer particle effects

## Next Steps

1. Run your game with performance monitoring enabled
2. Play through all stages and note any performance issues
3. Focus optimization on the areas with the biggest impact
4. Test on target hardware (not just development machine)

Remember: Optimize based on *measured* performance data, not assumptions!
