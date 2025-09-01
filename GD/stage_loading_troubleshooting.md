# Stage Loading Troubleshooting Guide

## Issue: Stage Configuration Files Not Loading

### Problem Description
The StageManager is unable to load any of the stage configuration .tres files, showing errors like:
```
❌ Failed to load stage_01_introduction.tres
❌ Failed to load stage_02_fish_intro.tres
... (all 6 files fail)
```

### Enhanced Debug Logging Added

I've added comprehensive debug logging to help identify the exact failure point:

```gdscript
🎯 StageManager singleton initialized
🔍 Checking class registration...
✅ StageConfiguration class is accessible
🔄 Loading initial stage...
📋 StageManager: Loading stage 1...
🔍 StageManager: Checking for file: res://scenes/configs/stages/stage_01_introduction.tres
✅ File exists, attempting to load...
🔄 StageManager: Loading resource from: res://scenes/configs/stages/stage_01_introduction.tres
🔍 Raw resource loaded: [Resource object]
🔍 Raw resource type: StageConfiguration
✅ Resource loaded and cast successfully, validating...
🔍 Validating configuration...
🔍 Validation result: true
✅ Configuration validated successfully
```

### Possible Causes & Solutions

#### 1. **Godot Project Not Reloaded**
**Cause**: After adding new custom classes, Godot sometimes needs a project reload.
**Solution**: 
- Close Godot completely
- Reopen the project
- Wait for full asset reimporting

#### 2. **Class Registration Issue**
**Cause**: The `class_name StageConfiguration` might not be registered properly.
**Solution**:
- Check that `scripts/systems/stage_configuration.gd` exists and has `class_name StageConfiguration`
- Verify no syntax errors in the script
- Force reimport the script file

#### 3. **AutoLoad Order Issue**
**Cause**: StageManager might be loading before StageConfiguration is registered.
**Solution**: 
- Check `project.godot` AutoLoad section
- Ensure StageManager is listed after other dependencies

#### 4. **File Path Case Sensitivity**
**Cause**: On case-sensitive systems, file paths might not match exactly.
**Solution**:
- Verify all file paths use exact case: `stage_01_introduction.tres`
- Check directory structure: `scenes/configs/stages/`

#### 5. **Resource Format Issues**
**Cause**: The .tres files might have format corruption.
**Solution**:
- Open one .tres file in text editor
- Verify it starts with: `[gd_resource type="StageConfiguration" script_class="StageConfiguration"...]`
- Recreate problematic .tres files in Godot editor

### Step-by-Step Debugging Process

1. **Run the game and check console output**
   - Look for the debug messages starting with 🎯, 🔍, ✅, ❌
   - Identify exactly where the failure occurs

2. **Check class accessibility**
   - Look for: `✅ StageConfiguration class is accessible`
   - If you see `❌ StageConfiguration class not accessible`, the issue is class registration

3. **Check file existence**
   - Look for: `✅ File exists, attempting to load...`
   - If you see `❌ File existence check failed`, the issue is file paths

4. **Check resource loading**
   - Look for: `🔍 Raw resource type: StageConfiguration`
   - If you see `null` or different type, the issue is resource format

5. **Check validation**
   - Look for: `✅ Configuration validated successfully`
   - If validation fails, check the StageConfiguration parameters

### Quick Fixes to Try

#### Fix 1: Force Project Reload
```
1. Save all files
2. Close Godot completely
3. Delete .godot folder (if safe to do so)
4. Reopen project
5. Wait for full reimport
6. Run the game
```

#### Fix 2: Verify Class Registration
```
1. Open scripts/systems/stage_configuration.gd
2. Verify first line is: class_name StageConfiguration
3. Check for any syntax errors
4. Right-click file → "Change Script" → "Attach Script" → Confirm it's registered
```

#### Fix 3: Recreate One Stage File
```
1. Delete scenes/configs/stages/stage_01_introduction.tres
2. In Godot editor: Create → Resource
3. Set script to StageConfiguration
4. Configure parameters
5. Save as stage_01_introduction.tres
6. Test if that single file loads
```

#### Fix 4: Manual File Check
```
1. Navigate to scenes/configs/stages/ in file manager
2. Verify all 6 .tres files exist
3. Open stage_01_introduction.tres in text editor
4. Verify format matches other working .tres files
```

### Expected Working Output

When the system works correctly, you should see:
```
🎯 StageManager singleton initialized
   Starting stage: 1
   Auto-difficulty: DISABLED
🔍 Checking class registration...
✅ StageConfiguration class is accessible
🔄 Loading initial stage...
📋 StageManager: Loading stage 1...
🔍 StageManager: Checking for file: res://scenes/configs/stages/stage_01_introduction.tres
✅ File exists, attempting to load...
🔄 StageManager: Loading resource from: res://scenes/configs/stages/stage_01_introduction.tres
🔍 Raw resource loaded: [StageConfiguration:1234567]
🔍 Raw resource type: StageConfiguration
✅ Resource loaded and cast successfully, validating...
🔍 Validating configuration...
🔍 Validation result: true
✅ Configuration validated successfully
✅ StageManager: Successfully loaded stage 1 - Introduction
   World Speed: 250.0
   Fish Enabled: false
   Nests Enabled: false
   Completion: TIMER (10.0)
✅ Initial stage loaded successfully
```

### If All Else Fails

Create a minimal test case:
1. Create a simple Resource script
2. Create a .tres file using that script
3. Try loading it with the same method
4. If that works, the issue is specific to StageConfiguration
5. If that fails, there's a deeper Godot project issue

### Recovery Plan

If the stage system still can't load:
1. The enhanced debug output will show exactly where it fails
2. We can implement a fallback system using JSON or hardcoded values
3. We can recreate the .tres files from scratch
4. We can modify the loading approach to be more robust

The debug logging will help us identify the exact cause and implement the right fix.
