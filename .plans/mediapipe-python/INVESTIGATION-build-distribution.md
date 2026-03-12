# INVESTIGATION: Build Distribution Strategy

**Goal:** Package Godot 4.6 + Python + MediaPipe into a distributable app that works on a clean PC

**Date:** 2026-02-07

---

## Architecture Overview

```
Final App Bundle
├── Godot Export (game.exe / MyApp.app / game)
│   └── Contains: GDScript, scenes, assets
├── Sidecar/ Folder
│   ├── python/           # Embedded Python runtime
│   │   ├── python.exe    # Windows
│   │   ├── python3       # Mac/Linux
│   │   └── Lib/          # Pre-installed packages
│   └── mediapipe_server/
│       ├── main.py
│       └── models/       # MediaPipe .tflite files
└── launcher/             # Godot auto-starts Python sidecar
```

---

## Distribution Options

### Option 1: Full Bundle (All-in-One)

**Approach:** Bundle everything including Python runtime

**Implementation:**
1. **Windows:** Use `python-3.x.x-embed-amd64.zip` (official embeddable Python)
2. **macOS:** Include `python.org` Framework build
3. **Linux:** Use system Python or AppImage with bundled Python
4. **Pre-install dependencies** into bundled Python's `Lib/site-packages/`
5. **MediaPipe models** bundled in `models/` folder

**Pros:**
- User downloads one file, double-clicks, it works
- No internet required after download
- Full control over versions

**Cons:**
- Large download (Python + MediaPipe + OpenCV ≈ 200-400MB)
- Platform-specific builds required
- Must handle code signing (macOS especially)

**Platform Details:**

**Windows:**
```
MyGame/
├── MyGame.exe          # Godot export
├── sidecar/
│   ├── python/         # python-3.11.8-embed-amd64
│   ├── mediapipe/
│   └── start_server.bat
└── _internal/          # PyInstaller-style if using that
```

**macOS:**
```
MyGame.app/
├── Contents/MacOS/MyGame      # Godot binary
├── Contents/Resources/
│   └── sidecar/
│       └── python/            # Python.framework
└── Contents/_CodeSignature/   # For notarization
```

---

### Option 2: Installer with Auto-Download

**Approach:** Small launcher that downloads Python + deps on first run

**Implementation:**
1. **Launcher:** Thin Godot app (or native executable)
2. **First-run check:** Detect if `sidecar/python/` exists
3. **Auto-download:** 
   - Download embeddable Python from python.org
   - Download MediaPipe wheels from PyPI
   - Install to local folder
4. **Progress UI:** Show download/install progress in Godot
5. **Cache:** Store in user's AppData/~/Library/Application Support/

**Pros:**
- Small initial download (just Godot game ≈ 50-100MB)
- Can update Python deps independently
- Works offline after first setup

**Cons:**
- Requires internet on first launch
- More complex error handling (download failures)
- Slower first-time experience

**Implementation Sketch:**
```gdscript
# In Godot AutoStartManager
const PYTHON_URL = "https://www.python.org/ftp/python/3.11.8/python-3.11.8-embed-amd64.zip"
const REQUIREMENTS = ["mediapipe==0.10.13", "opencv-python==4.8.1"]

func ensure_python() -> bool:
    if python_exists():
        return true
    
    show_download_ui()
    await download_python()
    await install_requirements()
    hide_download_ui()
    return true
```

---

### Option 3: PyInstaller Single Executable

**Approach:** Use PyInstaller to bundle Python + MediaPipe into one .exe

**Implementation:**
1. **Build Python side:** `pyinstaller --onefile --add-data "models;models" main.py`
2. **Output:** `mediapipe_server.exe` (≈ 150-300MB)
3. **Godot side:** Export normally
4. **Bundle together:** Both executables in same folder
5. **Godot launches:** `OS.execute("mediapipe_server.exe", [])`

**Pros:**
- Well-documented, battle-tested
- Handles Python dependencies automatically
- Single file for Python side

**Cons:**
- Slow startup (extracts to temp folder)
- AV false positives common
- Large file size
- One-size-fits-all, less control

**PyInstaller Spec:**
```python
# mediapipe_server.spec
a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('models/*', 'models')],
    hiddenimports=['mediapipe', 'cv2'],
    ...
)
```

---

### Option 4: Docker/Container (Advanced Users)

**Approach:** Ship as container for consistent environment

**Implementation:**
1. **Dockerfile:** Python + MediaPipe + network bridge
2. **Godot connects:** UDP to localhost:mapped_port
3. **Distribution:** Docker Hub or bundled Docker image

**Pros:**
- Perfect reproducibility
- Works on any Docker-capable system
- Easy updates

**Cons:**
- Requires Docker installed
- Not user-friendly for gamers
- Overkill for end-user distribution

**Use case:** Development, CI/CD, server deployments - NOT end users

---

## Recommended Path Forward

**Phase 1 (MVP):** Option 1 - Full Bundle
- Use embeddable Python on Windows
- Pre-install all deps
- Single folder, zip distribution
- **Goal:** Works on clean Windows PC

**Phase 2 (Polish):** Option 2 - Installer
- Small launcher downloads Python on first run
- Better UX, smaller initial download
- Auto-update capability

**Phase 3 (Scale):** Platform-specific polish
- Windows: MSI installer
- macOS: Signed .app bundle
- Linux: AppImage or Flatpak

---

## Key Technical Challenges

### 1. MediaPipe Model Files
- Must bundle `.tflite` model files
- MediaPipe downloads these on first run by default
- Need to pre-bundle and set `model_asset_path`

### 2. Camera Permissions
- Windows: No special permissions
- macOS: Requires `NSCameraUsageDescription` in Info.plist
- Linux: Usually works, may need `video` group

### 3. Code Signing (macOS)
- Unsigned apps show scary warning
- Apple Developer account required ($99/year)
- Notarization adds ~1hr to build process

### 4. Python Path Handling
- Godot must find Python executable reliably
- Use relative paths: `ProjectSettings.globalize_path("res://sidecar/python/python.exe")`

---

## Linux Bundle Implementation (Completed)

### Build Scripts Created

**Location:** `aerobeat-assembly-community/build-scripts/`

| Script | Purpose |
|--------|---------|
| `build-linux-bundle.sh` | Creates full Linux bundle with Python, MediaPipe, Godot export |
| `templates/run.sh` | Launcher that starts sidecar + game |

### Usage

```bash
# Build the bundle
cd aerobeat-assembly-community/build-scripts
./build-linux-bundle.sh

# Output: builds/dist/AeroBeat-Linux.tar.gz

# Test locally
cd builds/dist/AeroBeat-Linux
./run.sh
```

### What the Build Script Does

1. Creates Python venv with MediaPipe + OpenCV
2. Exports Godot project for Linux/X11
3. Copies Python environment to `sidecar/python/`
4. Copies MediaPipe server to `sidecar/mediapipe_server/`
5. Creates model download helper
6. Packages into `.tar.gz`

### Bundle Structure

```
AeroBeat-Linux/
├── aerobeat              # Godot Linux export
├── run.sh                # Launcher script
└── sidecar/
    ├── python/           # Full Python venv
    │   ├── bin/python3
    │   └── lib/python3.x/site-packages/  # MediaPipe, OpenCV, etc.
    ├── mediapipe_server/ # Python server files
    │   └── main.py
    └── download_models.py # Pre-downloads .tflite files
```

### Launcher Behavior

The `run.sh` script:
1. Checks for camera devices
2. Sets up bundled Python environment
3. Downloads MediaPipe models if missing
4. Starts Python sidecar in background
5. Launches Godot game
6. Cleans up sidecar on exit

### Next Steps

- [ ] Run build script on Zorin 18 Pro
- [ ] Test bundle on clean Linux VM
- [ ] Measure bundle size (expected: 200-400MB)
- [ ] Send test build to Chip's terminal for validation
- [ ] Create Windows version next
