# Nintendo Switch Joy-Con Support for Godot 4.6 - Research Report (2026)

**Document Date:** February 8, 2026  
**Project:** AeroBeat Joy-Con HID Input  
**Target Repository:** `~/Documents/GitHub/AeroBeat/aerobeat-input-joycon-hid/`

---

## Executive Summary

As of February 2026, **Godot 4.6 does NOT have native Joy-Con motion control support**. While basic button/stick input works via SDL3 (since Godot 4.5), gyroscope and accelerometer data from Joy-Cons require third-party libraries or custom GDExtension implementations. This document outlines the current state, available solutions, and implementation recommendations for AeroBeat.

---

## 1. Current State (Godot 4.6 - 2026)

### Native Godot Support

| Feature | Status | Notes |
|---------|--------|-------|
| Basic Button Input | ✅ Supported | Via SDL3 (since Godot 4.5) |
| Analog Sticks | ✅ Supported | Standard SDL gamepad support |
| Bluetooth Connection | ✅ Supported | Via OS HID stack |
| USB Connection | ⚠️ Partial | Experimental support exists |
| Gyroscope | ❌ Not Supported | No native API access |
| Accelerometer | ❌ Not Supported | No native API access |
| HD Rumble | ❌ Not Supported | No native API access |
| IR Camera | ❌ Not Supported | Not accessible via standard HID |

### Godot Official Position

- **GitHub Proposal #2829** (since June 2021): "Add support for controller-based motion controls (gyroscope, accelerometer)" - **Still Open**
- **GitHub Proposal #2908** (since June 2021): "Add support of gyroscope and accelerometer input from gamepads" - **Still Open**
- **GitHub Discussion #4420**: Community discussion on motion control support - **Ongoing**

The Godot team has acknowledged this as a valid feature request but has not committed to a timeline for native implementation.

---

## 2. Available Libraries & Tools

### A. JoyShockLibrary (Recommended for Implementation)

**Repository:** https://github.com/JibbSmart/JoyShockLibrary  
**License:** MIT License  
**Platforms:** Windows (compiled), Linux/Mac (source-compatible)

**Features:**
- Full Joy-Con support (Left, Right, and Pro Controller)
- Individual and combined controller modes
- **Gyroscope access** (3-axis, degrees per second)
- **Accelerometer access** (3-axis, g-force)
- Sensor fusion with quaternion output
- Touchpad support (DualShock/DualSense only)
- Automatic calibration
- Rumble support (basic)
- Player number LED control

**Key APIs:**
```c
IMU_STATE JslGetIMUState(int deviceId);  // Gyro + Accel
MOTION_STATE JslGetMotionState(int deviceId);  // Fused orientation
float JslGetGyroX/JslGetGyroY/JslGetGyroZ(int deviceId);
float JslGetAccelX/JslGetAccelY/JslGetAccelZ(int deviceId);
```

**AeroBeat Relevance:** ⭐⭐⭐⭐⭐  
This is the most mature, well-documented library for Joy-Con motion controls on PC.

---

### B. JoyShockLibrary-plus-HDRumble (HD Rumble Extension)

**Repository:** https://github.com/MIZUSHIKI/JoyShockLibrary-plus-HDRumble  
**License:** MIT License  

**Additional Features:**
- All features of base JoyShockLibrary
- **HD Rumble support** for Nintendo Switch devices
- Independent left/right HD rumble control

**HD Rumble API:**
```c
void JslSetHDRumble(int deviceId, float LowFrequency, float LowAmplitude, 
                    float HighFrequency, float HighAmplitude);
void JslSetHDRumbleLR(int deviceId, 
                      float LowFrequency_L, float LowAmplitude_L, 
                      float HighFrequency_L, float HighAmplitude_L,
                      float LowFrequency_R, float LowAmplitude_R, 
                      float HighFrequency_R, float HighAmplitude_R);
```

**Frequency Range:** Low 41-626Hz, High 82-1252Hz  
**Amplitude Range:** 0.0-1.0  
**Duration:** ~1 second per command

**AeroBeat Relevance:** ⭐⭐⭐⭐⭐  
HD rumble could provide tactile feedback during boxing motions.

---

### C. JoyCon-Driver (vJoy-based)

**Repository:** https://github.com/fossephate/JoyCon-Driver  
**License:** Open Source  
**Platform:** Windows

**Features:**
- vJoy feeder for Joy-Cons
- Combine Joy-Cons into single virtual controller
- Gyro mouse control
- Calibration support

**Limitations:**
- Windows only
- Requires vJoy installation
- Not suitable for direct integration
- End-user tool, not developer library

**AeroBeat Relevance:** ⭐⭐  
Useful for testing but not for shipping with AeroBeat.

---

### D. BetterJoy (End-User Tool)

**Repository:** https://github.com/Davidobot/BetterJoy  
**License:** Open Source  
**Platform:** Windows

**Features:**
- XInput wrapper for Joy-Cons
- Gyro mouse mapping
- CemuHook UDP protocol support
- System-wide controller support

**Limitations:**
- End-user application, not a library
- No programmatic API for developers
- Requires admin rights for some features

**AeroBeat Relevance:** ⭐  
Not suitable for integration. Recommend to users as workaround only.

---

### E. Linux HID Driver (Kernel Module)

**Repository:** https://github.com/Jo-Blade/linux-hid-joycon  
**License:** GPL

**Features:**
- Kernel-level Joy-Con driver for Linux
- Combines left/right Joy-Cons
- Standard joystick interface

**Limitations:**
- Linux only
- Requires kernel module installation
- Limited motion control exposure

**AeroBeat Relevance:** ⭐⭐⭐  
Useful for Linux support but not a complete solution.

---

## 3. Implementation Options for AeroBeat

### Option A: GDExtension with JoyShockLibrary (RECOMMENDED)

**Approach:** Create a Godot GDExtension that wraps JoyShockLibrary-plus-HDRumble

**Pros:**
- Native performance
- Full access to motion controls
- HD rumble support
- Works across platforms (Windows/Linux/Mac)
- Can expose custom GDScript API

**Cons:**
- Requires C++ development
- Platform-specific compilation needed
- Maintenance burden

**Implementation Steps:**
1. Set up GDExtension build system (SCons/cmake)
2. Link JoyShockLibrary-plus-HDRumble
3. Create wrapper classes:
   - `JoyConManager` (singleton for device discovery)
   - `JoyConDevice` (individual controller wrapper)
   - `JoyConMotion` (gyro/accel data structure)
4. Expose to GDScript
5. Handle platform differences

**Estimated Effort:** 2-3 weeks

---

### Option B: External Process + IPC

**Approach:** Run JoyShockLibrary in separate process, communicate via UDP/named pipes

**Pros:**
- GDScript-only in Godot
- Easier to debug
- Can use pre-built JoyShockLibrary DLL

**Cons:**
- IPC overhead
- Separate process management
- Less clean architecture

**Estimated Effort:** 1-2 weeks

---

### Option C: C# Module (Mono/.NET)

**Approach:** Use C# bindings for JoyShockLibrary with Godot's C# support

**Pros:**
- Easier than C++ for some developers
- Direct JoyShockLibrary C# bindings exist

**Cons:**
- Requires C# build of Godot
- May have marshalling overhead
- Less control over threading

**Estimated Effort:** 2 weeks

---

### Option D: Wait for Native Godot Support

**Pros:**
- No custom code needed
- Officially supported

**Cons:**
- No timeline (could be months/years)
- May not support all features (HD rumble unlikely)

**Estimated Timeline:** Unknown (not recommended)

---

## 4. Technical Feasibility Analysis

### Joy-Con as Camera Replacement for AeroBeat

| Aspect | Feasibility | Notes |
|--------|-------------|-------|
| Hand Position Tracking | ⚠️ Moderate | Joy-Cons don't track position in space, only rotation |
| Punch Detection | ✅ High | Accelerometer excellent for detecting punch motions |
| Motion Direction | ✅ High | Gyroscope provides accurate rotation data |
| Absolute Positioning | ❌ Low | No position tracking without external reference |
| Dual-Wield Support | ✅ High | Each Joy-Con reports independently |
| Latency | ✅ Excellent | ~5-15ms via Bluetooth |

**Verdict:** Joy-Cons can serve as an **alternative input method** for users without cameras, but they **cannot fully replace camera tracking** since they lack absolute position data. Best used for:
- Punch detection and classification
- Motion-based combo inputs
- Alternative input for users who prefer controllers

### Wrist Strap Safety

- Joy-Cons include wrist straps with locks
- Essential for boxing motions to prevent controller release
- Should be strongly recommended in documentation

---

## 5. Implementation Details

### Connection Modes

| Mode | Joy-Con L | Joy-Con R | Use Case |
|------|-----------|-----------|----------|
| Individual | Separate device | Separate device | Two-handed boxing |
| Combined | N/A | N/A | Single controller mode |
| Grip | Via charging grip | Via charging grip | Standard gamepad feel |

### Data Output Rates

- **Gyroscope/Accelerometer:** 5ms (200Hz) internal, 15ms (66Hz) reported
- **JoyShockLibrary averages 3 samples for smoother output**
- **Buttons/Sticks:** 15ms (66Hz)

### Coordinate Systems

Joy-Con IMU data:
- **Gyro:** degrees per second (dps)
- **Accel:** g-force (1g = 9.8 m/s²)
- **Orientation:** Quaternion or Euler angles (via sensor fusion)

---

## 6. Platform Considerations

| Platform | Support Level | Notes |
|----------|---------------|-------|
| Windows | ⭐⭐⭐⭐⭐ | Best support, all libraries work |
| Linux | ⭐⭐⭐⭐ | Kernel driver available, JoyShockLibrary portable |
| macOS | ⭐⭐⭐ | JoyShockLibrary should work, less tested |
| Android | ⭐⭐ | Some devices support Joy-Con, varies by manufacturer |
| iOS | ⭐ | No native Joy-Con support |
| Nintendo Switch | ⭐⭐⭐⭐⭐ | Official SDK (requires Nintendo authorization) |

### Nintendo Switch Homebrew

- Not officially supported by Godot
- Would require custom export template
- Outside scope of this research (focused on PC platforms)

---

## 7. Recommended Implementation Roadmap

### Phase 1: Prototype (Week 1-2)
- [ ] Set up GDExtension project structure
- [ ] Integrate JoyShockLibrary-plus-HDRumble
- [ ] Basic device detection and connection
- [ ] Expose gyro/accel data to GDScript

### Phase 2: Core Features (Week 3-4)
- [ ] Implement punch detection algorithm
- [ ] Add calibration system
- [ ] HD rumble feedback integration
- [ ] Combined/individual mode switching

### Phase 3: Integration (Week 5-6)
- [ ] AeroBeat input system integration
- [ ] Alternative to camera tracking mode
- [ ] UI for controller configuration
- [ ] Platform testing (Windows/Linux)

### Phase 4: Polish (Week 7-8)
- [ ] Performance optimization
- [ ] Documentation
- [ ] User onboarding flow
- [ ] Edge case handling

**Total Estimated Timeline: 6-8 weeks**

---

## 8. Key Source URLs

### Godot Official
- Console Support: https://godotengine.org/consoles/
- Controller Documentation: https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html
- Proposal #2829 (Motion Controls): https://github.com/godotengine/godot-proposals/issues/2829
- Proposal #2908 (Gyro/Accel): https://github.com/godotengine/godot-proposals/issues/2908
- Discussion #4420: https://github.com/godotengine/godot-proposals/discussions/4420

### Libraries
- JoyShockLibrary: https://github.com/JibbSmart/JoyShockLibrary
- JoyShockLibrary-plus-HDRumble: https://github.com/MIZUSHIKI/JoyShockLibrary-plus-HDRumble
- JoyCon-Driver: https://github.com/fossephate/JoyCon-Driver
- BetterJoy: https://github.com/Davidobot/BetterJoy
- Linux HID Driver: https://github.com/Jo-Blade/linux-hid-joycon

### Technical References
- HIDAPI: https://github.com/libusb/hidapi
- Nintendo Switch Reverse Engineering: https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering/
- GamepadMotionHelpers: https://github.com/JibbSmart/GamepadMotionHelpers
- GyroWiki: http://gyrowiki.jibbsmart.com
- JoyShockMapper: https://github.com/Electronicks/JoyShockMapper

### Community Resources
- Reddit r/GyroGaming: https://www.reddit.com/r/GyroGaming/
- Godot Forum - Motion Controls: https://forum.godotengine.org/t/using-accelerometer-gyroscope-information-from-a-controller/97106
- GBAtemp Joy-Con Discussion: https://gbatemp.net/

---

## 9. Conclusion & Recommendations

### Summary

1. **Godot 4.6 does not natively support Joy-Con motion controls** - third-party solution required
2. **JoyShockLibrary-plus-HDRumble is the best available option** - mature, MIT-licensed, feature-complete
3. **GDExtension is the recommended integration approach** - native performance, clean API
4. **Joy-Cons can supplement but not replace camera tracking** - excellent for punch detection, poor for absolute positioning
5. **Timeline: 6-8 weeks** for full implementation

### Final Recommendation

**Proceed with Option A: GDExtension with JoyShockLibrary-plus-HDRumble**

This approach provides:
- Full motion control access for AeroBeat
- HD rumble for tactile feedback
- Cross-platform support
- Clean integration with Godot's input system
- Future-proof architecture

### Next Steps

1. Create GDExtension project skeleton
2. Port JoyShockLibrary-plus-HDRumble to Godot 4.6
3. Build proof-of-concept punch detection
4. Integrate with AeroBeat input system
5. User testing with wrist straps

---

*Document prepared for AeroBeat development team. Last updated: 2026-02-08*
