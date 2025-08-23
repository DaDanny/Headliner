# Performance Baseline - Main Branch

**Date**: 2025-01-23  
**Branch**: main  
**Commit**: 1763341 (main branch baseline)  
**Build Status**: ✅ Clean compilation  

## Measurement Instructions

### 1. Memory Usage (Activity Monitor)
1. Launch Headliner.app from `/Applications/`
2. Open Activity Monitor → View → All Processes
3. Find "Headliner" process
4. Record **Memory** column value
5. Test camera selection 3 times, record peak memory

### 2. Camera Switch Performance
1. Open menu bar → Camera selection
2. Use stopwatch/timer to measure:
   - Time from click to camera list appearing
   - Time from selection to preview updating
3. Test with 3 different cameras if available

### 3. Extension Status Check
1. Time how long extension status takes to update
2. Record polling frequency (check Console.app for logs)

## Baseline Results (To Be Filled)

### Memory Usage
- **Startup Memory**: 192.5 MB
- **Peak Memory (camera active)**: 244.4 MB  
- **After 10 minutes idle**: ~192.5 MB

### Performance Timing
- **Camera list load time**: ___ ms (to be filled from docs/Baselines)
- **Camera switch time**: ___ ms (to be filled from docs/Baselines)
- **Extension status check**: ___ ms (to be filled from docs/Baselines)
- **App launch time**: ~20 seconds (from launch to menu bar ready)

### Architecture Analysis
- **AppState.swift**: 1036 lines (God Object)
- **Services**: Not integrated (CameraService, ExtensionService exist but unused)
- **Memory Pattern**: Single large object loaded at startup

---

## Post-Migration Comparison

*This section will be filled after the Big Bang Migration*

### Memory Usage (Target)
- **Startup Memory**: ___ MB (60% reduction target)
- **Peak Memory**: ___ MB
- **After 10 minutes**: ___ MB

### Performance Timing (Target)
- **Camera switch time**: <500ms (smooth)
- **Extension status**: Smart polling (1s → 4s backoff)
- **Background rendering**: Non-blocking

### Architecture (Target)  
- **Services**: <300 lines each
- **AppCoordinator**: <100 lines
- **Memory Pattern**: Lazy service loading