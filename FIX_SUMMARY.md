# Fix Summary: AeroBeat MediaPipe Python Input Provider

## Issues Fixed

### Issue 1: Python Sidecar Still Running After Godot Playback Stops

**Root Causes:**
1. The Python process had no way to detect if Godot had stopped/crashed
2. The cleanup in notification handlers (`_notification()`, `_exit_tree()`) used async/await which doesn't work properly in synchronous notification contexts
3. Process group termination wasn't reliable when OpenCV VideoCapture was in uninterruptible sleep (D state)

**Solution: Heartbeat/Keepalive Mechanism**
- Added UDP heartbeat from Godot to Python on port `udp_port + 1`
- Python monitors heartbeat - if no heartbeat received for 3 seconds, it self-terminates
- This ensures Python exits even if Godot crashes or is force-killed
- Heartbeat is sent every 500ms from both `MediaPipeProcess` and `AutoStartManager`

**Additional Improvements:**
- Added `_stop_sync()` method for synchronous cleanup in notification handlers
- Made notification handlers use synchronous cleanup to ensure it completes
- Stop heartbeat BEFORE sending SIGTERM so Python detects missing heartbeat and begins self-termination
- Added small delay after stopping heartbeat to let Python detect the missing signal

### Issue 2: Static Type Warnings

**Fixed in `mediapipe_process.gd`:**
```gdscript
func _read_process_group_id() -> int:
    var file: FileAccess = FileAccess.open(pid_file, FileAccess.READ)  # Added : FileAccess
    if file:
        var content: String = file.get_as_text().strip_edges()  # Added : String
        ...
```

**Fixed in `autostart_manager.gd`:**
```gdscript
func _read_pid_file(path: String) -> int:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)  # Added : FileAccess
    if file:
        var content: String = file.get_as_text().strip_edges()  # Added : String
        ...
```

## Files Modified

1. **`python_mediapipe/main.py`**
   - Added `update_heartbeat()`, `check_heartbeat()`, `heartbeat_monitor()` functions
   - Added UDP heartbeat socket on `port + 1`
   - Heartbeat thread monitors for missing heartbeats and triggers shutdown
   - Global `_heartbeat_last_time` tracks last heartbeat timestamp

2. **`src/process/mediapipe_process.gd`**
   - Fixed static types: `file: FileAccess`, `content: String`
   - Added heartbeat system (`_setup_heartbeat()`, `_send_heartbeat()`, `_stop_heartbeat()`)
   - Added `_stop_sync()` for synchronous cleanup
   - Updated `_notification()` handlers to use synchronous `_stop_sync()`
   - Updated `stop()` to stop heartbeat first before killing process

3. **`src/autostart_manager.gd`**
   - Fixed static types: `file: FileAccess`, `content: String`
   - Added heartbeat system (`_setup_heartbeat()`, `_send_heartbeat()`, `_stop_heartbeat()`)
   - Added `_stop_sync()` for synchronous cleanup
   - Updated `_notification()` handlers to use synchronous `_stop_sync()`
   - Updated `stop_server()` to stop heartbeat first

4. **`src/mediapipe_input_with_camera.gd`**
   - Added logging for debugging cleanup
   - Ensured `_notification()` handler calls `stop()`

5. **`src/providers/mediapipe_provider.gd`**
   - Added logging to `stop()` and `_notification()`

## How the Heartbeat Works

```
Godot Side                          Python Side
----------                          -----------
Send heartbeat ----UDP packet---->  update_heartbeat()
(every 500ms)                       timestamp = now
                                    
                                    watchdog checks:
                                    elapsed = now - timestamp
                                    if elapsed > 3s:
                                        _running = false
                                        exit main loop
                                        cleanup and exit
```

## Testing the Fix

1. Start Godot project with MediaPipe input
2. Verify Python process starts (`ps aux | grep mediapipe`)
3. Stop Godot playback (or close the window)
4. Check that Python process terminates within 3-4 seconds:
   ```bash
   ps aux | grep python_mediapipe
   # Should show no matching processes after ~3 seconds
   ```

## Fallback Behavior

If heartbeat fails for any reason:
1. Godot stops sending heartbeats
2. After 3 seconds, Python self-terminates
3. If process group kill is still attempted by Godot, Python may already be gone
4. This is fine - the kill will return an error (process not found) which is harmless

## Benefits

1. **Reliable termination**: Python exits even if Godot crashes
2. **No zombie processes**: Heartbeat timeout ensures cleanup
3. **Fast recovery**: 3-second timeout means fresh start is quick
4. **Debuggable**: Logging shows heartbeat status in both Godot and Python logs
