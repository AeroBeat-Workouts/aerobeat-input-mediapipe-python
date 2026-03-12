# MediaPipe & Godot 4.6 Optimization Research for Real-Time Body Tracking

**Research Date:** 2026-02-08  
**Project:** AeroBeat Motion Capture System  
**Scope:** Performance optimization techniques for MediaPipe pose detection and Godot 4.6 networking

---

## Summary of Search Queries Performed

1. "MediaPipe pose detection optimization 2024 2025"
2. "MediaPipe GPU acceleration Linux real-time performance"
3. "MediaPipe frame skipping decimation performance"
4. "Godot 4 multiplayer networking optimization UDP"
5. "Godot 4 ENet multiplayer performance optimization"
6. "One Euro filter body tracking smoothing alternative"
7. "body tracking latency reduction motion capture optimization 2024"
8. "skeletal animation smoothing techniques real-time"
9. "MediaPipe pose landmark detection Python API options"

---

## 1. MediaPipe Performance Optimization (2024-2025)

### Key Findings

#### 1.1 Two-Step Detector-Tracker Pipeline
MediaPipe uses a proven two-step detector-tracker ML pipeline approach:
- **Detection step:** Locates person/pose ROI within the frame (slower, runs periodically)
- **Tracking step:** Tracks landmarks within the detected ROI (faster, runs every frame)
- This approach has been validated in MediaPipe Hands and Face Mesh solutions

**Source:** https://github.com/google-ai-edge/mediapipe/blob/master/docs/solutions/pose.md  
**Relevance to AeroBeat:** HIGH - Already using this approach, but understanding it helps optimize parameters

#### 1.2 BlazePose Model Variants
MediaPipe Pose uses BlazePose model variants based on MobileNetV2 architecture:
- **Heavy model:** Most accurate, slower
- **Full model:** Balanced accuracy/speed
- **Lite model:** Fastest, lower accuracy
- All variants use GHUM (3D human shape modeling pipeline) for 3D estimation

**Source:** https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker  
**Relevance to AeroBeat:** HIGH - May benefit from model selection based on hardware capabilities

#### 1.3 GPU Acceleration on Linux (Critical Finding)
**Important limitation:** MediaPipe Python GPU acceleration on Linux x86-64 has documented issues:
- GitHub issue #5742 (Nov 2024): "mediapipe not GPU accelerated" on Linux
- GitHub issue #4410: Users requesting GPU acceleration for Python solutions
- OpenGL ES 3.1+ required for ML inference on Android/Linux
- **Benchmark data:** CPU processing can actually be FASTER than GPU on some configurations (1.24x faster in one test)

**Optimization recommendations:**
- Test CPU vs GPU performance on target hardware
- Multiple GL contexts can be useful for separating inference (10 FPS) from rendering (30 FPS)
- Consider using the same GL context for both tasks to reduce frame rate reduction

**Sources:**
- https://stackoverflow.com/questions/77707532/how-to-check-for-and-enforce-gpu-usage-for-mediapipe-frame-processing
- https://github.com/google-ai-edge/mediapipe/issues/5742
- https://mediapipe.readthedocs.io/en/latest/framework_concepts/gpu.html  
**Relevance to AeroBeat:** HIGH - Current Linux setup may not benefit from GPU acceleration; CPU optimization is critical

#### 1.4 Frame Rate & Performance Issues
Common performance pitfalls identified:
- **Multiple model initialization:** Initializing the model multiple times causes framerate degradation
- **Memory leaks:** Multiple video file loads can decrease FPS over time
- **Detection confidence trade-offs:** Lower `min_detection_confidence` and `min_tracking_confidence` can improve speed

**Recommended parameters for performance:**
```python
mpPose.Pose(
    min_detection_confidence=0.5,  # Lower for speed (default: 0.5)
    min_tracking_confidence=0.5,   # Lower for speed (default: 0.5)
    model_complexity=0              # 0=Light, 1=Full, 2=Heavy
)
```

**Sources:**
- https://stackoverflow.com/questions/68745309/how-to-make-mediapipe-pose-estimation-faster-python
- https://github.com/google/mediapipe/issues/3158  
**Relevance to AeroBeat:** HIGH - Can immediately apply these parameter optimizations

#### 1.5 Research Paper: Efficient Human Pose Estimation (June 2024)
A 2024 research paper (arXiv:2406.15649v1) presents:
- Novel modifications to MediaPipe for improved accuracy
- Enhanced performance in dynamic movements and partial occlusions
- Computational speed gains validated through benchmarking
- Focus on mobile and embedded systems compatibility
- Implementation code available at: https://github.com/avhixd/Human_pose_estimation

**Source:** https://arxiv.org/html/2406.15649v1  
**Relevance to AeroBeat:** MEDIUM - Review the implementation for potential algorithm improvements

---

## 2. Godot 4.6 Networking Optimization

### Key Findings

#### 2.1 ENet Multiplayer Architecture
Godot 4.0+ introduces significant networking improvements:
- **ENetMultiplayerPeer:** Renamed from NetworkedMultiplayerENet with enhanced features
- **Low-level ENet access:** ENetConnection (host) and ENetPacketPeer (peer) wrappers
- **DTLS support:** Optional encryption via `dtls_server_setup()` and `dtls_client_setup()`

**Key ENet features exposed:**
- Round-trip time (RTT) measurement
- Ping/pong functionality
- Configurable timeouts
- Bandwidth limits
- Multiple channels for ordered/unordered delivery

**Source:** https://godotengine.org/article/multiplayer-changes-godot-4-0-report-3/  
**Relevance to AeroBeat:** HIGH - Should review current UDP implementation vs built-in ENet

#### 2.2 MultiplayerAPI and Scene Replication
Godot 4 provides:
- Seamless peer-to-peer and client-server architectures
- RPC (Remote Procedure Call) with configurable reliability:
  ```gdscript
  @rpc("any_peer", "reliable")    # TCP-like
  @rpc("any_peer", "unreliable")  # UDP-like
  @rpc("any_peer", "unreliable_ordered")  # Ordered UDP
  ```
- Built-in scene replication for state synchronization

**Source:** https://godotawesome.com/godot-4-multiplayer-networking-guide-2025/  
**Relevance to AeroBeat:** MEDIUM - Current raw UDP works, but ENet might offer better reliability options

#### 2.3 Protocol Considerations
- Godot's high-level multiplayer uses UDP-based protocol with optional reliability
- Implements optional reliability and packet ordering on top of UDP
- Avoids TCP's congestion control and Nagle's algorithm issues
- For custom implementations: PacketPeerUDP and UDPServer available

**Source:** https://docs.godotengine.org/en/3.1/tutorials/networking/high_level_multiplayer.html  
**Relevance to AeroBeat:** MEDIUM - Current implementation follows best practices

#### 2.4 Third-Party Enhancement: godot-enet-better
Community module offering enhanced ENet performance:
- https://github.com/Faless/godot-enet-better
- Designed for high-performance multiplayer games
- May offer better performance at scale (64+ players)

**Relevance to AeroBeat:** LOW - Current 1-to-1 camera-Godot setup doesn't need scaling

---

## 3. Real-Time Body Tracking Optimization

### Key Findings

#### 3.1 Motion Capture Pipeline Optimization
Modern approaches achieving significant improvements:
- **Ultra Inertial Poser (2024):** 97% reduction in jitter through novel algorithms
- **Rokoko Smartsuit Pro II:** Sensor Fusion 2.0 algorithm reduces magnetic interference by 24%
- **NOKOV systems:** Sub-millimeter accuracy with minimal latency

**Source:** https://www.emergentmind.com/papers/2404.19541  
**Relevance to AeroBeat:** MEDIUM - Algorithmic insights applicable to post-processing

#### 3.2 Network Latency Compensation
Research shows:
- Pose forecasting can compensate for network latency in VR applications
- Critical for multi-user VR with full-body motion data transmission
- Prediction algorithms reduce perceived latency

**Source:** https://link.springer.com/chapter/10.1007/978-3-032-03805-0_3  
**Relevance to AeroBeat:** MEDIUM - Could implement prediction on Godot side for smoother rendering

#### 3.3 Wearable Deep Learning Systems (2025)
Recent Nature Communications paper demonstrates:
- Deep learning integration enables low-latency, accurate motion classification
- Real-time bidirectional feedback systems
- Sensor-haptic networks for full-body capture

**Source:** https://www.nature.com/articles/s41467-025-63644-3  
**Relevance to AeroBeat:** LOW - Hardware-focused, but validates DL approaches for tracking

---

## 4. Smoothing & Filtering Techniques

### Key Findings

#### 4.1 One Euro Filter (1€ Filter)
The gold standard for real-time input smoothing:
- **Mechanism:** First-order low-pass filter with adaptive cutoff frequency
- **Behavior:** Low cutoff at low speeds (reduces jitter), high cutoff at high speeds (reduces lag)
- **Parameters:**
  - `min_cutoff`: Minimum cutoff frequency (reduces jitter)
  - `beta`: Speed coefficient (reduces lag)
- **Advantages:** Easy to implement, minimal resources, easy to tune
- **Validation:** Outperforms LaViola's double exponential smoothing and Kalman filters in jitter-lag tradeoff

**Implementation formula:**
```python
alpha = 1 / (1 + (1/(2*pi*cutoff)))
filtered = alpha * raw + (1 - alpha) * previous_filtered
```

**Sources:**
- https://inria.hal.science/hal-00670496v1/document
- https://dl.acm.org/doi/10.1145/2207676.2208639  
**Relevance to AeroBeat:** HIGH - Already implemented, but parameters may need tuning

#### 4.2 N-euro Predictor: Neural Network Approach (2023)
Novel deep learning-based smoothing:
- Addresses jitter-lag tradeoff better than traditional filters
- Uses neural network for prediction and smoothing
- Outperforms One Euro Filter in both jitter and lag metrics
- Paper: "120 N-euro Predictor: A Neural Network Approach for Smoothing"

**Source:** https://jianwang-cmu.github.io/23Neuro/N_euro_predictor.pdf  
**Relevance to AeroBeat:** MEDIUM - Could experiment with ML-based smoothing as an alternative

#### 4.3 Double Exponential Smoothing (LaViola)
Alternative to One Euro Filter:
- Simpler implementation
- Higher lag for same jitter reduction (0.013 SEM vs 0.004 SEM for 1€)
- Good for less demanding applications

**Relevance to AeroBeat:** LOW - One Euro is superior, no reason to switch

#### 4.4 Kalman Filter
Traditional approach for body tracking:
- Optimal for linear systems with Gaussian noise
- More complex to tune (requires motion model)
- Outperformed by One Euro Filter for human motion (non-linear)

**Relevance to AeroBeat:** LOW - One Euro Filter is better suited for this use case

---

## 5. Actionable Recommendations for AeroBeat

### Immediate Actions (High Impact, Low Effort)

1. **MediaPipe Parameter Optimization**
   - Test `model_complexity=0` (Lite) for higher frame rates
   - Tune `min_detection_confidence` and `min_tracking_confidence` (try 0.3-0.5)
   - Profile CPU vs GPU on target Linux hardware
   - **Expected gain:** 20-50% FPS improvement

2. **Verify Single Model Instance**
   - Ensure pose estimator is initialized once and reused
   - Check for memory leaks during long captures
   - **Expected gain:** Prevents FPS degradation over time

3. **One Euro Filter Tuning**
   - Current implementation should be validated
   - Recommended starting values:
     - `min_cutoff = 1.0` Hz (jitter reduction)
     - `beta = 0.007` (lag reduction)
   - Tune based on actual motion characteristics

### Medium-Term Improvements (High Impact, Medium Effort)

4. **Frame Processing Pipeline**
   - Implement frame skipping/decimation for processing
   - Process every Nth frame, interpolate between
   - Consider running detection at 15 FPS, tracking at 30 FPS
   - **Expected gain:** Reduced CPU load, maintained smoothness

5. **Godot ENet Migration**
   - Evaluate moving from raw UDP to ENetMultiplayerPeer
   - Benefits: Built-in reliability options, congestion control, DTLS support
   - Test RPC reliability modes for different data types:
     - `unreliable` for rapid pose updates
     - `unreliable_ordered` for sequences

6. **Prediction Implementation**
   - Add pose prediction on Godot side for latency compensation
   - Simple linear extrapolation based on velocity
   - Could reduce perceived latency by 1-2 frames

### Research & Development (High Impact, High Effort)

7. **N-euro Predictor Evaluation**
   - Review the neural network smoothing paper
   - Implement prototype for comparison with One Euro
   - Train on captured motion data if needed
   - **Potential gain:** Better jitter-lag tradeoff

8. **MediaPipe Research Implementation**
   - Review the 2024 research paper improvements
   - Check if algorithmic modifications can be integrated
   - Evaluate the open-source implementation

9. **Sensor Fusion Approach**
   - Consider fusing MediaPipe with IMU data if available
   - Could reduce jitter and handle occlusions better
   - **Relevance:** For future hardware iterations

---

## 6. Sources & References

### MediaPipe Documentation
- https://github.com/google-ai-edge/mediapipe/blob/master/docs/solutions/pose.md
- https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker
- https://ai.google.dev/edge/mediapipe/framework/framework_concepts/gpu
- https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/python

### GitHub Issues & Discussions
- https://github.com/google-ai-edge/mediapipe/issues/5742 (GPU on Linux)
- https://github.com/google/mediapipe/issues/4410 (Python GPU)
- https://github.com/google/mediapipe/issues/3158 (Low FPS)
- https://github.com/Faless/godot-enet-better

### Stack Overflow & Forums
- https://stackoverflow.com/questions/77707532/how-to-check-for-and-enforce-gpu-usage-for-mediapipe-frame-processing
- https://stackoverflow.com/questions/68745309/how-to-make-mediapipe-pose-estimation-faster-python
- https://forum.godotengine.org/t/can-godot-netcode-scale-for-large-multiplayer-scenarios/83561

### Research Papers
- Efficient Human Pose Estimation (June 2024): https://arxiv.org/html/2406.15649v1
- N-euro Predictor: https://jianwang-cmu.github.io/23Neuro/N_euro_predictor.pdf
- 1€ Filter Paper: https://inria.hal.science/hal-00670496v1/document
- ACM 1€ Filter: https://dl.acm.org/doi/10.1145/2207676.2208639
- Ultra Inertial Poser: https://www.emergentmind.com/papers/2404.19541
- Nature Wearable Systems: https://www.nature.com/articles/s41467-025-63644-3

### Godot Documentation
- https://godotengine.org/article/multiplayer-changes-godot-4-0-report-3/
- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html
- https://godotawesome.com/godot-4-multiplayer-networking-guide-2025/

### Smoothing & Animation
- One Euro Filter Implementation: https://mohamedalirashad.github.io/FreeFaceMoCap/2021-12-25-filters-for-stability/
- Skeletal Animation Guide: https://garagefarm.net/blog/skeletal-animation-a-comprehensive-guide
- LearnOpenGL Skeletal Animation: https://learnopengl.com/Guest-Articles/2020/Skeletal-Animation

---

## 7. Relevance Summary Table

| Topic | Relevance | Action Priority |
|-------|-----------|-----------------|
| MediaPipe GPU on Linux | HIGH | Investigate CPU vs GPU |
| MediaPipe Parameters | HIGH | Immediate tuning |
| MediaPipe Model Selection | HIGH | Test Lite model |
| Godot ENet Migration | MEDIUM | Evaluate vs current UDP |
| One Euro Filter Tuning | HIGH | Validate current implementation |
| N-euro Predictor | MEDIUM | Research for future |
| Frame Skipping | MEDIUM | Implement if CPU-bound |
| Pose Prediction | MEDIUM | Add to Godot side |
| Research Paper Algorithms | LOW | Review for insights |

---

*Document compiled from web research on 2026-02-08*
