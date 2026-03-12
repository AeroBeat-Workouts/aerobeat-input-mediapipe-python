# AeroBeat MediaPipe Python Repository Cleanup Plan

## Repository Audit Summary

**Location:** `/home/derrick/Documents/GitHub/AeroBeat/aerobeat-input-mediapipe-python/`

---

## 1. CURRENT REPOSITORY STRUCTURE

### Root Directory Files
```
├── AGENTS.md                          # Documentation
├── CAMERA_STREAMING.md                # Documentation
├── CLAUDE.md                          # Documentation (minimal - 14 bytes)
├── COMPREHENSIVE_TEST_REPORT.md       # Documentation
├── LICENSE.md                         # Documentation
├── README.md                          # Documentation
├── .gdignore                          # Git/Config
├── .gitignore                         # Git/Config
├── install_deps.bat                   # Setup script
├── install_deps.sh                    # Setup script
├── plugin.cfg                         # Godot config
├── project.godot.standalone           # Godot config
├── requirements.txt                   # Dependencies
├── setup_dev.py                       # Setup script
├── pose_landmarker_full.task          # ML Model (9.4MB)
├── pose_landmarker_heavy.task         # ML Model (30.6MB)
├── pose_landmarker_lite.task          # ML Model (5.8MB)
```

### Source Code Directories
```
src/                                    # Main source code
├── autostart_manager.gd
├── camera_view.gd
├── mediapipe_input_with_camera.gd
├── config/
│   └── mediapipe_config.gd
├── process/
│   └── mediapipe_process.gd
├── providers/
│   └── mediapipe_provider.gd
├── server/
│   └── mediapipe_server.gd
└── strategies/
    └── strategy_mediapipe.gd

python_mediapipe/                       # Python sidecar
├── main.py
├── args.py
├── camera_streamer.py
├── metrics_collector.py
├── mock_server.py
├── one_euro_filter.py
├── platform_utils.py
├── roi_tracker.py
├── test_filter.py
├── test_runner.py
├── requirements.txt
└── .gdignore

test/                                   # Test files
├── landmark_drawer.gd
├── mediapipe_provider_test.gd
├── test_mediapipe_logic.gd
├── test_scene.gd
├── test_scene.tscn
├── mocks/
│   └── mock_mediapipe_server.py
└── unit/
    ├── test_mediapipe_process.gd
    ├── test_mediapipe_provider.gd
    └── test_mediapipe_server.gd
```

### .testbed/ Directory Structure
```
.testbed/                               # Godot project testbed
├── .godot/                             # Godot editor cache (SHOULD NOT COMMIT)
├── venv/                               # Python virtual environment (SHOULD NOT COMMIT)
│   └── ...site-packages (hundreds of files)
├── .testbed/                           # NESTED .testbed (duplicate!)
│   └── venv/                           # Another venv (SHOULD NOT COMMIT)
├── addons/                             # Symlinked addons
├── project.godot                       # Godot project file
├── pose_landmarker_full.task           # DUPLICATE ML Model
├── pose_landmarker_heavy.task          # DUPLICATE ML Model
├── pose_landmarker_lite.task           # DUPLICATE ML Model
├── python_mediapipe -> (symlink)       # Symlink to root python_mediapipe
├── src -> (symlink)                    # Symlink to root src
└── test/                               # DUPLICATE test files
    ├── landmark_drawer.gd              # DIFFERENT from root/test/
    ├── mediapipe_provider_test.gd      # DIFFERENT from root/test/
    ├── test_mediapipe_logic.gd         # DIFFERENT from root/test/
    ├── test_scene.gd                   # DIFFERENT from root/test/
    ├── test_runner.gd                  # NOT in root/test/
    ├── test_phase5.gd                  # NOT in root/test/
    ├── test_script_this_should_work.gd # NOT in root/test/
    ├── test_scene.tscn                 # DUPLICATE
    └── test_scripts_on_this_scene.tscn # NOT in root/test/
```

### Large Test Assets (Root Directory)
```
test_*.mp4 files (6 videos): ~65MB total
test_*.json files: ~3.5MB total
report_*.json files (25 reports): ~5MB total
```

---

## 2. FILES TO REMOVE

### A. Cache/Derived Files (Add to .gitignore)
| File/Directory | Reason | Size |
|---------------|--------|------|
| `.testbed/.godot/` | Godot editor cache | ~50MB |
| `python_mediapipe/__pycache__/` | Python bytecode cache | ~100KB |
| `.testbed/venv/` | Python virtual environment | ~500MB |
| `.testbed/.testbed/venv/` | Duplicate venv | ~500MB |
| `.testbed/.testbed/` | Accidentally nested directory | Variable |
| `*.pyc` files | Python compiled bytecode | Scattered |
| `*.uid` files | Godot 4 UID files (can be regenerated) | Many |

### B. Duplicate ML Models (Keep only root copies)
| File | Location | Action |
|------|----------|--------|
| `pose_landmarker_full.task` | `.testbed/` | DELETE (keep root) |
| `pose_landmarker_heavy.task` | `.testbed/` | DELETE (keep root) |
| `pose_landmarker_lite.task` | `.testbed/` | DELETE (keep root) |

### C. Nested .testbed Directory
```
.testbed/.testbed/          # ENTIRE DIRECTORY - created by accident
├── venv/                   # Contains another venv
├── ...
```
**Action:** Delete entire `.testbed/.testbed/` directory

### D. Obsolete Test Reports (Optional)
The 25 `report_*.json` files appear to be test output artifacts:
- `report_baseline_*.json` (5 files)
- `report_both_*.json` (5 files)
- `report_preprocess_*.json` (5 files)
- `report_roi_*.json` (5 files)

**Recommendation:** Move to `test_results/` subdirectory or delete if not needed for CI

### E. Test Video Files (Consider .gitignore or LFS)
```
test_*.mp4 (6 files, ~65MB):
- test_boxing.mp4
- test_female_boxer.mp4
- test_group_dance.mp4
- test_hiphop_dance.mp4
- test_punching_bag.mp4
- test_shadow_boxing.mp4
```
**Recommendation:** Either:
1. Add to `.gitignore` (if generated/downloaded during setup)
2. Use Git LFS (if they must be versioned)
3. Keep as-is (if they're small enough and needed)

---

## 3. FILES TO KEEP BUT ORGANIZE

### A. Duplicate GD Scripts (Different Versions!)
**Important:** The following files exist in BOTH `test/` and `.testbed/test/` but have DIFFERENT content:

1. **`test_scene.gd`**
   - `test/test_scene.gd`: Uses AutoStartManager + CameraView (newer version)
   - `.testbed/test/test_scene.gd`: Uses camera feed directly (older version)
   
2. **`mediapipe_provider_test.gd`**
   - `test/`: Has debug print statements
   - `.testbed/test/`: Clean version without prints
   
3. **`test_mediapipe_logic.gd`**
   - `test/`: Full test suite with GUT compatibility
   - `.testbed/test/`: Empty/different file
   
4. **`landmark_drawer.gd`**
   - `test/`: Different coordinate handling
   - `.testbed/test/`: Uses typed GDScript with different X flip logic

**Recommendation:** These appear to be divergent versions. The `.testbed/test/` versions seem to be the actively developed versions. Consider:
- Keeping `.testbed/test/` versions as the "canonical" test versions
- Archiving or removing `test/` versions if they're obsolete
- OR consolidate into single location

### B. Test Files Unique to .testbed/test/ (Keep)
```
.testbed/test/
├── test_runner.gd              # Test runner script
├── test_phase5.gd              # Phase 5 specific tests
├── test_script_this_should_work.gd  # Integration test
└── test_scripts_on_this_scene.tscn  # Test scene
```
**Action:** Move these to root `test/` directory

---

## 4. RECOMMENDED FINAL STRUCTURE

```
aerobeat-input-mediapipe-python/
├── .github/
│   └── workflows/
├── .testbed/                      # Godot test project
│   ├── addons/                    # Symlink to root
│   ├── src -> ../src/             # Symlink
│   ├── python_mediapipe -> ../python_mediapipe/  # Symlink
│   ├── test/                      # REMOVE - use root test/
│   ├── project.godot
│   └── .gdignore
├── src/                           # Main GDScript source
├── python_mediapipe/              # Python sidecar
├── test/                          # All test files consolidated
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests (from .testbed/test/)
│   └── assets/                    # Test videos (optional)
├── docs/                          # Documentation (move MD files here)
├── models/                        # ML Models (move .task files here)
├── test_results/                  # Test output (add to .gitignore)
├── .gitignore                     # Update with patterns below
├── plugin.cfg
├── requirements.txt
└── README.md
```

---

## 5. .gitignore UPDATES NEEDED

Add these patterns:

```gitignore
# Godot
.godot/
*.uid
.import/
export.cfg
export_presets.cfg

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
venv/
.env/

# Test artifacts
test_results/
*.log

# Large media files (optional - uncomment if needed)
# *.mp4
# *.mov
# *.avi

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

---

## 6. CLEANUP ACTION CHECKLIST

### Phase 1: Remove Cache/Derived Files
- [ ] Delete `.testbed/.godot/`
- [ ] Delete `.testbed/venv/`
- [ ] Delete `.testbed/.testbed/` (entire nested directory)
- [ ] Delete `python_mediapipe/__pycache__/`
- [ ] Delete all `*.uid` files (optional - can be regenerated)

### Phase 2: Remove Duplicate ML Models
- [ ] Delete `.testbed/pose_landmarker_*.task` (3 files)

### Phase 3: Consolidate Test Files
- [ ] Compare and decide: `test/` vs `.testbed/test/` versions
- [ ] Move unique files from `.testbed/test/` to `test/`
  - `test_runner.gd`
  - `test_phase5.gd`
  - `test_script_this_should_work.gd`
  - `test_scripts_on_this_scene.tscn`
- [ ] Delete `.testbed/test/` directory after consolidation
- [ ] Update symlinks if needed

### Phase 4: Organize Root Directory
- [ ] Create `models/` directory
- [ ] Move `pose_landmarker_*.task` files to `models/`
- [ ] Create `test_results/` directory (and add to .gitignore)
- [ ] Move `report_*.json` files to `test_results/` (or delete)
- [ ] Create `docs/` directory (optional)
- [ ] Move documentation MD files to `docs/` (optional)

### Phase 5: Update Configuration
- [ ] Update `.gitignore` with new patterns
- [ ] Update any paths in `project.godot` that reference moved files
- [ ] Update `plugin.cfg` if needed
- [ ] Update README with new structure

---

## 7. ESTIMATED SPACE SAVINGS

| Category | Estimated Size | Action |
|----------|---------------|--------|
| `.testbed/.godot/` | ~50MB | Delete |
| `.testbed/venv/` | ~500MB | Delete |
| `.testbed/.testbed/venv/` | ~500MB | Delete |
| `__pycache__/` files | ~1MB | Delete |
| Duplicate ML models | ~46MB | Delete duplicates |
| Test videos (if removed) | ~65MB | Move to LFS or gitignore |
| Test reports | ~5MB | Move to subdirectory |
| **Total Potential Savings** | **~1.1GB** | |

---

## 8. NOTES AND WARNINGS

1. **Symlinks:** The `.testbed/` directory contains symlinks to `src/` and `python_mediapipe/`. Do not break these.

2. **Active Development:** Some files in `.testbed/test/` appear more recently developed than `test/` versions. Carefully compare before deleting.

3. **CLAUDE.md:** This file is only 14 bytes - essentially empty. Can be deleted.

4. **Test Videos:** The 6 MP4 files are ~65MB total. Consider if these should be:
   - Kept (if essential for testing)
   - Moved to Git LFS
   - Downloaded via script during setup

5. **GUT Integration:** Some test files reference GUT (Godot Unit Testing). Ensure test structure is compatible.

---

## 9. POST-CLEANUP VERIFICATION

After cleanup, verify:
- [ ] Godot project opens without errors
- [ ] Tests can still run
- [ ] Python sidecar starts correctly
- [ ] No broken symlinks
- [ ] All essential files present

---

*Generated: 2026-02-10*
*This is a PLAN only - no files have been modified*
