# AeroBeat macOS Optimizations Guide

**Document Version:** 1.0  
**Date:** 2026-02-07  
**Applies To:** AeroBeat MediaPipe + Godot 4.6 Setup on macOS

---

## 1. MediaPipe on macOS

### 1.1 Current State of GPU Support

**Critical Finding:** MediaPipe Python on macOS has **limited GPU acceleration options** compared to Linux/Windows.

#### The Reality Check
- MediaPipe Python uses **TensorFlow Lite XNNPACK delegate for CPU** by default on macOS
- **No official Metal GPU delegate** for MediaPipe Python on macOS desktop
- GitHub issues [#4896](https://github.com/google-ai-edge/mediapipe/issues/4896) and [#5656](https://github.com/google-ai-edge/mediapipe/issues/5656) confirm GPU support gaps
- Building GPU-enabled MediaPipe from source on macOS requires complex Bazel configuration and often fails

#### What Actually Works
```python
# Current MediaPipe on macOS uses CPU delegate
import mediapipe as mp

# This will show: "Created TensorFlow Lite XNNPACK delegate for CPU"
# No Metal GPU acceleration available for Python API
```

### 1.2 Apple Silicon (M1/M2/M3/M4) Considerations

#### Native ARM64 vs Rosetta
- **Always use native ARM64** - Rosetta emulation significantly reduces performance
- MediaPipe now provides native Apple Silicon wheels (no longer need `mediapipe-silicon` workaround)
- Python 3.9+ recommended for best Apple Silicon support

#### Installation Best Practices
```bash
# Use Homebrew Python (ARM64 native)
brew install python@3.11

# Install MediaPipe (automatically selects ARM64 wheel)
pip install mediapipe

# Verify architecture
file $(which python3)  # Should show "arm64" not "x86_64"
```

### 1.3 Core ML Integration (Limited)

**Status:** MediaPipe does not currently expose Core ML delegate through Python API.

- Core ML delegate exists in MediaPipe C++ framework
- Would require custom build or wrapper to access from Python
- Neural Engine (ANE) access is not available through standard MediaPipe Python

### 1.4 Performance Expectations

| Platform | GPU Delegate | Typical FPS (Hand Tracking) |
|----------|--------------|----------------------------|
| Windows | DirectML/CUDA | 60+ FPS |
| Linux | OpenGL/Vulkan | 60+ FPS |
| **macOS (Apple Silicon)** | **CPU only** | **30-45 FPS** |
| macOS (Intel) | CPU only | 15-25 FPS |

**Key Insight:** Expect **25-40% lower performance** on macOS compared to Windows/Linux due to CPU-only inference.

---

## 2. macOS-Specific Optimizations

### 2.1 App Nap Prevention (CRITICAL)

App Nap can severely impact real-time performance by throttling background processes.

#### System-Wide Disable (Development)
```bash
# Disable App Nap globally
defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

# Re-enable (when needed)
defaults delete NSGlobalDomain NSAppSleepDisabled
```

#### Per-Application Disable (Production)
```bash
# For Godot app
defaults write org.godotengine.godot NSAppSleepDisabled -bool YES

# For custom Python app (replace com.yourcompany.app)
defaults write com.yourcompany.aerobeat NSAppSleepDisabled -bool YES
```

#### Info.plist Configuration
Add to `Info.plist` in your app bundle:
```xml
<key>LSAppNapIsDisabled</key>
<true/>
```

### 2.2 Process Priority

macOS `nice` values work differently than Linux:

```python
import os
import psutil

# Set high priority (requires root for negative values)
process = psutil.Process()
process.nice(-10)  # May require sudo

# Alternative: Use QoS (Quality of Service) via pyobjc
# This is the macOS-native way
```

**Note:** For real-time audio/video, consider using `NSThread` with `NSQualityOfServiceUserInteractive` via PyObjC.

### 2.3 Metal vs OpenGL in Godot

#### Godot 4.6 Renderer Selection
- **Forward+ renderer** uses Metal on macOS (via MoltenVK or native Metal)
- **Compatibility renderer** uses OpenGL

**Recommendation:** Use Forward+ renderer for best performance on Apple Silicon:
```ini
# project.godot
[rendering]
renderer/rendering_method="forward_plus"
```

### 2.4 Camera Access Permissions

macOS requires explicit privacy permissions for camera access.

#### Required Info.plist Entries
```xml
<key>NSCameraUsageDescription</key>
<string>AeroBeat requires camera access for hand tracking and gesture recognition.</string>

<key>NSMicrophoneUsageDescription</key>
<string>AeroBeat requires microphone access for audio processing.</string>
```

#### TCC (Transparency, Consent, and Control) Database
Camera permissions are stored in:
```
~/Library/Application Support/com.apple.TCC/TCC.db
```

**Important:** Command-line Python scripts may not trigger permission dialogs properly. Bundle as `.app` for reliable permission handling.

### 2.5 Network Permissions

For UDP networking, no explicit permissions are needed for localhost/inbound connections, but for distribution:

```xml
<!-- For sandboxed apps -->
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

---

## 3. Godot 4.6 on macOS

### 3.1 Metal Renderer Performance

- Godot 4.6 uses **MoltenVK** (Vulkan over Metal) on macOS
- Native Metal backend is in development for future versions
- Apple Silicon shows **excellent performance** with Forward+ renderer

### 3.2 Export Template Considerations

#### Universal Binary
Godot 4.6 exports as **Universal 2 binary** by default:
- Includes both `x86_64` (Intel) and `arm64` (Apple Silicon) architectures
- Single `.app` bundle works on all Macs
- Bundle size increases (~2x) but simplifies distribution

#### Export Requirements
1. Valid **Bundle Identifier** (e.g., `com.yourcompany.aerobeat`)
2. Export templates downloaded via Editor > Manage Export Templates
3. For distribution: Code signing + Notarization (see Section 4)

### 3.3 App Bundle Structure

```
AeroBeat.app/
├── Contents/
│   ├── Info.plist          # App metadata, permissions
│   ├── MacOS/
│   │   └── AeroBeat        # Main executable (Godot)
│   ├── Resources/
│   │   └── ...             # App resources
│   └── Helpers/            # Helper executables
│       └── python_tracker  # MediaPipe Python process
```

### 3.4 Sandboxing Requirements

**For App Store Distribution:**
- Must enable **App Sandbox**
- Cannot use `OS.execute()` for external binaries outside bundle
- Helper executables must be declared in entitlements

**For Direct Distribution:**
- Sandboxing optional
- More flexibility with helper processes

---

## 4. Build & Distribution

### 4.1 Code Signing

#### Options Overview

| Signing Type | Cost | Gatekeeper Behavior |
|--------------|------|---------------------|
| Apple Developer ID | $99/year | ✅ Runs without warnings |
| Ad-hoc (Built-in) | Free | ⚠️ User must bypass Gatekeeper |
| None | Free | ❌ Blocked on Apple Silicon |

#### Ad-hoc Signing (Free Distribution)
```bash
# Godot can ad-hoc sign automatically
# In Export settings: Code Signing > Codesign = "Built-in (ad-hoc only)"

# Manual ad-hoc signing if needed:
codesign -s - --force --deep "AeroBeat.app"
```

#### Developer ID Signing
```bash
# With Apple Developer certificate installed:
codesign -s "Developer ID Application: Your Name" --force --deep "AeroBeat.app"
```

### 4.2 Notarization Requirements

**Notarization is required** for apps distributed outside the App Store to avoid Gatekeeper warnings.

#### Using Xcode notarytool (Recommended)
```bash
# Submit for notarization
xcrun notarytool submit "AeroBeat.dmg" \
  --apple-id "your@email.com" \
  --team-id "ABCD123456" \
  --wait

# Staple ticket to app
xcrun stapler staple "AeroBeat.app"
```

#### Godot Export Integration
Godot 4.6 supports automated notarization:
- Export settings: Notarization > Xcode notarytool
- Provide App Store Connect API credentials

### 4.3 Gatekeeper Compatibility

#### User Workarounds (Unsigned Apps)
Users must either:
1. Right-click > Open (first launch only)
2. System Settings > Privacy & Security > "Allow Anyway"
3. Remove quarantine attribute:
   ```bash
   xattr -dr com.apple.quarantine "AeroBeat.app"
   ```

#### Recommended Approach
- Use **ad-hoc signing** at minimum (free)
- Provide clear instructions for Gatekeeper bypass
- Consider Apple Developer ID for polished distribution

### 4.4 Universal Binary Creation

Godot handles this automatically, but for custom helper binaries:

```bash
# Create universal binary from separate architectures
lipo -create -output "universal_binary" \
  "binary_x86_64" \
  "binary_arm64"

# Verify
lipo -archs "universal_binary"  # Should print: x86_64 arm64
```

### 4.5 Distribution Formats

| Format | Pros | Cons |
|--------|------|------|
| **.dmg** | Professional, drag-drop install | macOS-only creation |
| **.zip** | Simple, cross-platform creation | No custom branding |
| **.pkg** | Installer, admin rights | More complex |

**Recommendation:** Use `.dmg` for professional distribution, `.zip` for beta/development.

---

## 5. Hardware Considerations

### 5.1 Apple Silicon vs Intel Macs

| Feature | Apple Silicon (M1/M2/M3/M4) | Intel Macs |
|---------|----------------------------|------------|
| MediaPipe Performance | 30-45 FPS (CPU) | 15-25 FPS (CPU) |
| Godot Rendering | Excellent (Metal) | Good |
| Power Efficiency | 2x+ better | Higher power draw |
| Neural Engine | Available (limited access) | N/A |
| Thermal Throttling | Less common | More common |

### 5.2 Unified Memory Architecture

**Advantages for AeroBeat:**
- **Zero-copy** data sharing between CPU and GPU
- No PCIe bottleneck for texture/landmark data
- Large memory pools (up to 128GB on M2 Ultra)

**Practical Impact:**
- UDP packet buffers can be larger
- Godot texture uploads are faster
- Lower latency for real-time processing

### 5.3 Neural Engine Usage

**Current Limitations:**
- MediaPipe does not access ANE through Python API
- Core ML models can use ANE, but requires separate implementation
- For maximum ANE utilization, would need Core ML conversion

**Future Consideration:**
- Convert MediaPipe models to Core ML format
- Use `coremltools` for model conversion
- Potential 2-3x inference speedup on ANE

### 5.4 Thermal Throttling

#### Monitoring
```bash
# Check thermal state
sudo powermetrics --samplers smc -n 1

# Monitor CPU/GPU throttling
sudo thermal levels
```

#### Mitigation
- Keep sustained CPU usage below 80% per core
- Use `qos_class` to manage thermal impact
- Consider performance cores (P-cores) only on M1 Pro/Max/Ultra

---

## 6. Potential Blockers & Issues

### 6.1 Known Issues

| Issue | Severity | Workaround |
|-------|----------|------------|
| MediaPipe no GPU on macOS | High | Use CPU, optimize model complexity |
| Camera permission dialogs | Medium | Bundle as .app with proper Info.plist |
| Gatekeeper blocking | Medium | Ad-hoc sign, provide user instructions |
| App Nap throttling | High | Disable via defaults or Info.plist |
| Rosetta performance | High | Ensure ARM64 native binaries |

### 6.2 Development Blockers

1. **Cannot build MediaPipe with GPU from source easily**
   - Bazel build system complex on macOS
   - Missing `GetCVPixelBufferRef` errors common
   - **Decision:** Use official wheels, accept CPU inference

2. **Python embedded in Godot bundle**
   - Sandboxed apps cannot execute external Python
   - **Solution:** Include Python in `Contents/Helpers/`, declare in entitlements

3. **UDP networking in sandbox**
   - Requires `com.apple.security.network.server` entitlement
   - **Solution:** Enable in export settings

### 6.3 Deployment Blockers

1. **Notarization requires Apple Developer account ($99/year)**
   - Alternative: Ad-hoc sign + user instructions

2. **Python dependencies in bundle**
   - Use `py2app`, `PyInstaller`, or manual venv bundling
   - Ensure all dylibs are signed

---

## 7. Recommendations Summary

### Development Setup
1. Use **native ARM64 Homebrew Python** (not Rosetta)
2. Install MediaPipe via pip (uses optimized wheels)
3. Disable App Nap during development
4. Test on both Intel and Apple Silicon if possible

### Godot Configuration
1. Use **Forward+ renderer** for best Metal performance
2. Set proper **Bundle Identifier**
3. Enable **Audio Input** and **Camera** entitlements
4. Include **camera_usage_description** in export settings

### Distribution Strategy
1. **Minimum:** Ad-hoc sign + DMG + Gatekeeper instructions
2. **Recommended:** Apple Developer ID + Notarization + DMG
3. **App Store:** Requires sandboxing, helper process limitations

### Performance Optimization
1. **Accept CPU-only MediaPipe** - optimize by reducing model complexity
2. **Use unified memory** - share buffers between processes efficiently
3. **Disable App Nap** - critical for real-time performance
4. **Profile on target hardware** - Apple Silicon vs Intel vary significantly

---

## 8. References

- [MediaPipe GitHub - macOS GPU Issues](https://github.com/google-ai-edge/mediapipe/issues/5656)
- [Godot macOS Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
- [Apple Developer - Code Signing](https://developer.apple.com/documentation/xcode/code-signing)
- [Apple Developer - Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [TensorFlow Metal Plugin](https://developer.apple.com/metal/tensorflow-plugin/)

---

**Document Status:** Research Complete  
**Next Steps:** Implement macOS build pipeline, test on M1/M2 hardware
