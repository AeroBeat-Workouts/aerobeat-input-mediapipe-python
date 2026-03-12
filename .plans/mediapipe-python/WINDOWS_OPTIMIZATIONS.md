# Windows 11 Optimizations for AeroBeat

**Platform:** Windows 11  
**Target:** MediaPipe Python + Godot 4.6  
**Priority:** After Linux (Zorin)  

---

## Key Finding: No GPU Acceleration on Windows

**Critical:** MediaPipe Python from PyPI does **NOT** support GPU acceleration on Windows.

- GitHub Issue #5385 confirms: `delegate=mp.tasks.BaseOptions.Delegate.GPU` fails on Windows
- CPU inference is the only option with official PyPI package
- GPU would require building MediaPipe from source with custom flags
- **Recommendation:** Stick with CPU on Windows (same approach as Linux)

---

## Performance Expectations

| Metric | Linux (Current) | Windows 11 | Notes |
|--------|-----------------|------------|-------|
| **Latency** | 11.6ms avg | ~12-15ms | Slightly higher |
| **FPS** | 81 FPS | ~60-70 FPS | Good enough for 30fps target |
| **Inference** | 8-9ms | ~10-12ms | Windows overhead |

**Expected Impact:** 20-30% performance reduction vs Linux, still well within targets.

---

## Windows-Specific Optimizations

### 1. Process Priority (High Impact)

```python
import ctypes
from ctypes import wintypes

def set_high_priority():
    """Set process to high priority on Windows"""
    kernel32 = ctypes.windll.kernel32
    handle = kernel32.GetCurrentProcess()
    # HIGH_PRIORITY_CLASS = 0x00000080
    kernel32.SetPriorityClass(handle, 0x00000080)
```

**Alternative:** Use `psutil` (cross-platform):
```python
import psutil
import os

p = psutil.Process(os.getpid())
p.nice(psutil.HIGH_PRIORITY_CLASS)  # Windows-specific
```

### 2. CPU Affinity

Pin MediaPipe to specific cores, leave others for Godot:

```python
import psutil
import os

p = psutil.Process(os.getpid())
# Use cores 0-1 for MediaPipe, leave 2-3 for Godot
p.cpu_affinity([0, 1])
```

### 3. Windows Defender Exclusions

**Critical for performance:** Add game folder to Windows Defender exclusions.

```powershell
# Run as Administrator
Add-MpPreference -ExclusionPath "C:\Path\To\AeroBeat"
```

**Why:** Real-time scanning can add 5-15ms latency to file operations.

### 4. Power Plan

Set to High Performance mode:

```powershell
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

Or guide users to: Settings → System → Power → Best Performance

### 5. Windows Game Mode

Enable Windows Game Mode for consistent performance:
- Settings → Gaming → Game Mode → ON
- Prevents Windows Update interruptions
- Prioritizes game processes

---

## Godot 4.6 on Windows

### Export Settings

From Godot docs:
- Export creates optimized binary (smaller, faster than editor)
- Avoid PCK embedding (causes antivirus false positives)
- Use external `.pck` file

### Code Signing

```
Requirements:
- Windows SDK (for SignTool.exe) OR osslsigncode on Linux/Mac
- Code signing certificate ($200-400/year)

Note: Not required for indie distribution, but recommended for:
- Steam
- Microsoft Store
- Avoiding SmartScreen warnings
```

### Render Settings

```gdscript
# Project Settings for Windows
Rendering → Driver → Windows: "d3d12" or "vulkan"
# D3D12 often better on Windows 11

Threading → Worker Thread Pool:
- Low-end: 2 threads
- Mid-range: 4 threads  
- High-end: 8 threads
```

---

## Build & Distribution

### Windows Bundle Structure

```
aerobeat-windows/
├── AeroBeat.exe          # Godot export template
├── AeroBeat.pck          # Game data (not embedded)
├── python_mediapipe/     # Python sidecar
│   ├── main.py
│   ├── pose_landmarker_lite.task
│   └── requirements.txt
├── python/               # Bundled Python (via embeddable)
├── run.bat               # Launcher script
└── README.txt
```

### Python Distribution on Windows

**Option A: Embeddable Python (Recommended)**
- Download from python.org (Windows embeddable package)
- ~15MB minimal footprint
- No installer required

**Option B: Full Python Install**
- Users must install Python 3.11+
- More compatible but higher friction

### VC++ Redistributables

Bundle `vc_redist.x64.exe` or statically link:
- Python 3.11+ requires VS 2017+ redist
- Most Windows 11 systems already have this

---

## Hardware Considerations

### CPU

| Vendor | Notes |
|--------|-------|
| **Intel** | Good single-thread performance, AVX-512 not needed |
| **AMD** | Slightly better multi-thread, excellent value |

MediaPipe is single-threaded for inference, so clock speed > core count.

### GPU

MediaPipe won't use GPU on Windows with PyPI package.
- NVIDIA/AMD/Intel all fine for Godot rendering
- No inference offload benefit

### Camera

USB camera latency can vary:
- **Avoid:** Cheap no-name webcams (high latency drivers)
- **Recommended:** Logitech C920/C922, Razer Kiyo
- **Best:** DSLR via capture card (lowest latency)

---

## Windows-Specific Implementation

### Batch Launcher

```batch
@echo off
setlocal

:: Set high priority
wmic process where name="python.exe" CALL setpriority 128

:: Run MediaPipe sidecar
start /high python\python.exe python_mediapipe\main.py

:: Run Godot game
start /high AeroBeat.exe
```

### Registry Settings (Optional)

```reg
Windows Registry Editor Version 5.00

; Disable fullscreen optimizations
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_FSEBehaviorMode"=dword:00000002

; Disable GameDVR for lower latency
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000
```

---

## Testing Checklist

- [ ] Test on Windows 11 Home and Pro
- [ ] Test with Windows Defender enabled (measure impact)
- [ ] Test with different power plans
- [ ] Test USB camera latency vs Linux
- [ ] Verify process priority is set
- [ ] Check antivirus false positives
- [ ] Test on Intel and AMD CPUs

---

## Summary

**Performance:** Expect ~20-30% reduction vs Linux, still hitting 12-15ms (well under 25-45ms target)

**Key Actions:**
1. No GPU acceleration available (use CPU)
2. Set process priority to HIGH
3. Add to Windows Defender exclusions
4. Use High Performance power plan
5. Enable Game Mode
6. Bundle embeddable Python

**No Major Blockers** - Windows 11 is a viable target! 🎯
