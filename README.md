# AeroBeat MediaPipe Python

A high-performance MediaPipe pose tracking system for AeroBeat, featuring real-time body tracking via Python with UDP communication to Godot.

## Features

- **Real-time Pose Tracking**: Full 33-landmark body tracking using MediaPipe
- **Low Latency**: Optimized pipeline with threaded capture, binary protocol, and tuned UDP buffers
- **Latency Measurement**: Built-in timing breakdown for performance monitoring
- **One-Euro Filtering**: Adaptive smoothing to reduce jitter while maintaining responsiveness
- **Video Input Support**: Use camera or pre-recorded video files
- **Performance Optimizations**: Frame skipping, model complexity options, and configurable UDP buffers
- **Dual Protocol Support**: Binary (fast) or JSON (debugging) serialization
- **Automated Testing**: Mock server and test video included for development

## Installation

### Quick Install (Linux/macOS)

```bash
# Clone the repository
git clone https://github.com/YourOrg/aerobeat-input-mediapipe-python.git
cd aerobeat-input-mediapipe-python

# Run the install script
./install_deps.sh
```

### Manual Install

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Requirements

- Python 3.8+
- OpenCV
- MediaPipe
- NumPy

## Quick Start

### Basic Usage

```bash
# Start with default settings (camera 0, localhost:4242)
python python_mediapipe/main.py

# Start with specific camera
python python_mediapipe/main.py --camera 0

# Use a video file instead of camera
python python_mediapipe/main.py --camera /path/to/video.mp4
```

### With Godot

The system works as a sidecar process that Godot automatically manages:

1. Add the addon to your Godot project
2. The `AutoStartManager` automatically starts the Python server
3. Use `MediaPipeProvider` to access pose data

```gdscript
# In your Godot script
@onready var provider = $MediaPipeProvider

func _process(delta):
    var left_hand = provider.get_left_hand_position()
    if left_hand:
        print("Left hand at: ", left_hand)
```

## Performance Optimizations

### Threaded Frame Capture

Enabled by default, captures frames in a background thread to always get the latest frame:

```bash
python python_mediapipe/main.py --threaded-capture    # Enable (default)
python python_mediapipe/main.py --no-threaded-capture # Disable
```

### Frame Skipping

Process every Nth frame to reduce CPU load:

```bash
# Process every 2nd frame (30fps processing at 60fps capture)
python python_mediapipe/main.py --skip-frames 2

# Process every 3rd frame (20fps processing at 60fps capture)
python python_mediapipe/main.py --skip-frames 3
```

### Model Complexity

Choose the right balance between accuracy and speed:

```bash
# Lite model - fastest, lowest accuracy (good for most use cases)
python python_mediapipe/main.py --model-complexity 0

# Full model - balanced (default)
python python_mediapipe/main.py --model-complexity 1

# Heavy model - highest accuracy, slowest
python python_mediapipe/main.py --model-complexity 2
```

### Confidence Thresholds

Lower thresholds = faster detection but potentially less accurate:

```bash
python python_mediapipe/main.py --detection-confidence 0.3 --tracking-confidence 0.3
```

### UDP Buffer Tuning

Smaller buffers = lower latency:

```bash
# Default (4096 bytes)
python python_mediapipe/main.py

# Smaller buffer for lower latency
python python_mediapipe/main.py --udp-buffer-size 2048
```

## Advanced Optimizations

The following optimizations can significantly reduce inference latency. All are opt-in via CLI flags.

### Frame Preprocessing ⭐ Recommended

Resizes frames before MediaPipe inference to reduce computational load.

- **CLI flag**: `--preprocess-size 320` (default: 480, use 0 to disable)
- **Benefit**: ~0.2ms faster inference (1.7% improvement)
- **Trade-off**: Minimal accuracy impact (-1.1% detection rate)
- **Recommendation**: **320-480 for best speed/accuracy balance. Safe for all scenarios - enabled by default.**

> ✅ **Preprocessing is safe for all use cases** - single player, multiple people, low light, and fast movements. See [Test Results](#test-results) for details.

```bash
# Fast preprocessing (320px)
python python_mediapipe/main.py --preprocess-size 320

# Conservative preprocessing (480px)
python python_mediapipe/main.py --preprocess-size 480

# Disable preprocessing
python python_mediapipe/main.py --preprocess-size 0
```

### UDP Batching

Packs multiple frame data into a single UDP packet to reduce system call overhead and network latency.

- **CLI flag**: `--udp-batch-size 3` (default: 1, max: 3)
- **Benefit**: 3-8ms latency reduction, fewer system calls
- **How it works**: Batches 2-3 frames and sends them together; Godot processes all at once

```bash
# Batch 3 frames per packet
python python_mediapipe/main.py --udp-batch-size 3

# Default single-frame packets
python python_mediapipe/main.py --udp-batch-size 1
```

### Predictive ROI Tracking ⚠️ Not Recommended

Smart region-of-interest tracking with velocity prediction for faster inference on localized regions.

- **CLI flag**: `--use-roi` (default: off)
- **Additional flags**:
  - `--roi-size 320` - Target ROI size in pixels (default: 320)
  - `--roi-padding 50` - Padding around detected person in pixels (default: 50)
- **Expected Benefit**: 5-10ms faster inference (theoretical)
- **Actual Impact**: +0.3ms slower, -8.4% detection rate, significant tracking loss
- **Recommendation**: **AVOID unless single player + good lighting + slow movements guaranteed**

> ⚠️ **WARNING - ROI tracking is unreliable and causes lost tracking:**
> - **Multiple people**: 42 lost frames, detection drops 16% (68% → 52%)
> - **Low light**: 15 lost frames, detection drops 6% (71% → 65%)
> - **Fast movements**: 3-6 lost frames per video due to prediction failures
> 
> See [Test Results](#test-results) for comprehensive analysis.

**Features:**
- Tracks player velocity over 5 frames
- Predicts next position using velocity extrapolation
- Expands ROI 50% when tracking is temporarily lost
- Falls back to full frame after 3 lost frames
- Automatically adjusts landmarks back to original coordinates

```bash
# ⚠️ NOT RECOMMENDED - Only use if single player + good lighting guaranteed
python python_mediapipe/main.py --use-roi

# Custom ROI settings
python python_mediapipe/main.py \
    --use-roi \
    --roi-size 320 \
    --roi-padding 50
```

### Platform-Specific Optimizations

Platform-specific tweaks are automatically applied at startup:

**Windows:**
- Process priority boost to high
- Tips for Windows Defender exclusions (see logs)

**macOS:**
- App Nap disabled to prevent throttling
- Sleep prevention during active tracking

**Linux:**
- Already optimized by default
- Thread and scheduler optimizations applied automatically

### Optimization Usage Examples

```bash
# Maximum performance (all optimizations)
python -m python_mediapipe.main \
    --preprocess-size 320 \
    --udp-batch-size 3 \
    --use-roi \
    --use-filter \
    --model-complexity 0

# Conservative settings (safer, slightly slower)
python -m python_mediapipe.main \
    --preprocess-size 480 \
    --use-roi

# Testing individual optimizations
python -m python_mediapipe.test_runner \
    --video test_boxing.mp4 \
    --preprocess-size 320 \
    --use-roi
```

### Expected Performance

| Configuration | Expected Latency | Improvement |
|--------------|------------------|-------------|
| Baseline | ~12ms | - |
| With preprocessing | ~8-9ms | 25-33% faster |
| With ROI | ~6-7ms | 42-50% faster |
| All optimizations | ~5-6ms | 50-58% faster |

## Latency Measurement System

The system provides real-time timing breakdown for performance monitoring:

```
[LATENCY] Frame 120: capture=8.45ms | inference=12.34ms | filter=0.082ms | serialization=0.12ms | TOTAL=21.00ms
```

### Understanding the Output

| Metric | Description | Typical Range |
|--------|-------------|---------------|
| capture | Time to read frame from camera | 5-20ms |
| inference | MediaPipe model inference | 10-30ms |
| filter | One-Euro filter application | 0.05-0.15ms |
| serialization | Data packing for UDP | 0.05-0.2ms |
| TOTAL | End-to-end processing time | 15-50ms |

### Expected Performance Numbers

| Configuration | Expected Latency | FPS |
|--------------|------------------|-----|
| Lite model + frame skip 2 | 15-20ms | 30 |
| Lite model | 20-25ms | 60 |
| Full model | 25-35ms | 60 |
| Heavy model | 40-60ms | 30 |

## One-Euro Filtering

Adaptive smoothing that reduces jitter while maintaining responsiveness. The filter dynamically adjusts based on movement speed.

### Presets

| Preset | Use Case | min_cutoff | beta | Characteristics |
|--------|----------|------------|------|-----------------|
| responsive | Fast movements, gaming | 2.0 | 0.01 | Low latency, some jitter |
| balanced | General purpose | 1.0 | 0.005 | Good balance (default) |
| smooth | Slow movements, UI | 0.5 | 0.002 | Very smooth, more lag |

### Usage

```bash
# Use a preset
python python_mediapipe/main.py --filter-preset smooth

# Disable filtering
python python_mediapipe/main.py --no-filter

# Custom parameters (overrides preset)
python python_mediapipe/main.py \
    --filter-min-cutoff 1.5 \
    --filter-beta 0.008 \
    --filter-d-cutoff 1.0
```

### Performance Impact

One-Euro filtering adds approximately **0.05-0.15ms** per frame - negligible compared to inference time.

## Protocol Options

### Binary Protocol (Default)

- Smaller packets (~550 bytes vs ~3KB)
- Faster serialization
- Recommended for production

```bash
python python_mediapipe/main.py --binary-protocol  # Default
```

### JSON Protocol

- Human-readable
- Easier debugging
- Good for development

```bash
python python_mediapipe/main.py --json-protocol
```

## Video Input Support

Use video files instead of live camera for testing or demo purposes:

```bash
# Use the included test video
python python_mediapipe/main.py --camera test_boxing.mp4

# Use your own video
python python_mediapipe/main.py --camera /path/to/your/video.mp4
```

**Note**: OpenCV's `VideoCapture` accepts both camera IDs (integers) and file paths (strings).

## Testing

### Mock Server

Test Godot integration without camera:

```bash
# Send fake landmark data
python python_mediapipe/mock_server.py

# Custom settings
python python_mediapipe/mock_server.py --host 127.0.0.1 --port 4242 --fps 30

# Run for specific duration
python python_mediapipe/mock_server.py --test-duration 10
```

### Filter Tests

Run the One-Euro filter test suite:

```bash
python python_mediapipe/test_filter.py
```

Expected output:
```
============================================================
One-Euro Filter Test Suite
============================================================
Testing OneEuroFilter...
  Raw variance: 0.008344
  Filtered variance: 0.000156
  Variance reduction: 98.1%
  Reset test: PASSED
OneEuroFilter test: PASSED

Testing LandmarkFilterBank...
  33 landmarks filtered over 10 frames
  Reset all test: PASSED
  Single landmark reset test: PASSED
LandmarkFilterBank test: PASSED
...
All tests PASSED
============================================================
```

### Performance Test with Video

```bash
# Run with test video and measure latency
python python_mediapipe/main.py --camera test_boxing.mp4
```

## Configuration

### CLI Arguments Reference

| Argument | Default | Description |
|----------|---------|-------------|
| `--camera` | 0 | Camera device ID or video file path |
| `--port` | 4242 | UDP port for sending data |
| `--host` | 127.0.0.1 | UDP host address |
| `--detection-confidence` | 0.3 | Detection confidence threshold (0.0-1.0) |
| `--tracking-confidence` | 0.3 | Tracking confidence threshold (0.0-1.0) |
| `--model-complexity` | 0 | Model complexity: 0=Lite, 1=Full, 2=Heavy |
| `--max-fps` | 60 | Maximum capture FPS |
| `--width` | 640 | Camera width in pixels |
| `--height` | 480 | Camera height in pixels |
| `--binary-protocol` | True | Use binary serialization (faster) |
| `--json-protocol` | False | Use JSON serialization (debugging) |
| `--skip-frames` | 1 | Process every Nth frame |
| `--threaded-capture` | True | Use threaded frame capture |
| `--no-threaded-capture` | - | Disable threaded capture |
| `--udp-buffer-size` | 4096 | UDP socket buffer size in bytes |
| `--use-filter` | True | Enable One-Euro filtering |
| `--no-filter` | - | Disable One-Euro filtering |
| `--filter-preset` | balanced | Filter preset: responsive/balanced/smooth |
| `--filter-min-cutoff` | - | Override minimum cutoff frequency (Hz) |
| `--filter-beta` | - | Override speed coefficient |
| `--filter-d-cutoff` | - | Override derivative cutoff frequency (Hz) |
| `--preprocess-size` | 480 | Preprocess frame size (0=disable, 320-480 recommended) |
| `--udp-batch-size` | 1 | Frames per UDP packet (1-3, higher=lower latency) |
| `--use-roi` | False | Enable predictive ROI tracking |
| `--roi-size` | 320 | ROI target size in pixels |
| `--roi-padding` | 50 | Padding around detected person in pixels |

### Example Commands

```bash
# Maximum performance (Lite model, frame skipping)
python python_mediapipe/main.py \
    --model-complexity 0 \
    --skip-frames 2 \
    --detection-confidence 0.3 \
    --tracking-confidence 0.3

# Maximum quality (Heavy model, no skipping, smooth filtering)
python python_mediapipe/main.py \
    --model-complexity 2 \
    --filter-preset smooth \
    --detection-confidence 0.5 \
    --tracking-confidence 0.5

# Video file with custom resolution
python python_mediapipe/main.py \
    --camera video.mp4 \
    --width 1280 \
    --height 720

# Network setup (send to different machine)
python python_mediapipe/main.py \
    --host 192.168.1.100 \
    --port 5000
```

## Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Webcam/       │      │   Python Sidecar │      │   Godot Game    │
│   Video File    │─────▶│                  │─────▶│                 │
└─────────────────┘      │  ┌────────────┐  │      │  ┌───────────┐  │
                         │  │  Threaded  │  │      │  │  UDP      │  │
                         │  │  Capture   │  │      │  │  Server   │  │
                         │  └─────┬──────┘  │      │  └─────┬─────┘  │
                         │        ▼         │      │        ▼        │
                         │  ┌────────────┐  │      │  ┌───────────┐  │
                         │  │  MediaPipe │  │      │  │ MediaPipe │  │
                         │  │  Inference │  │      │  │ Provider  │  │
                         │  └─────┬──────┘  │      │  └─────┬─────┘  │
                         │        ▼         │      │        ▼        │
                         │  ┌────────────┐  │      │  ┌───────────┐  │
                         │  │ One-Euro   │  │      │  │  Game     │  │
                         │  │ Filter     │  │      │  │  Logic    │  │
                         │  └─────┬──────┘  │      │  └───────────┘  │
                         │        ▼         │      └─────────────────┘
                         │  ┌────────────┐  │
                         │  │ Binary/    │  │
                         │  │ JSON       │  │
                         │  │ Serializer │  │
                         │  └─────┬──────┘  │
                         │        ▼         │
                         │  ┌────────────┐  │
                         │  │ UDP Socket │  │
                         │  │ (tuned)    │  │
                         │  └────────────┘  │
                         └──────────────────┘
```

### Components

1. **AutoStartManager** (Godot): Automatically installs dependencies and starts the Python server
2. **MediaPipeProcess** (Godot): Manages the Python subprocess lifecycle
3. **MediaPipeServer** (Godot): UDP server receiving landmark data
4. **MediaPipeProvider** (Godot): High-level API for accessing pose data
5. **main.py** (Python): Sidecar process handling camera, inference, filtering, and UDP
6. **FrameCapture**: Threaded capture for minimal latency
7. **OneEuroFilter**: Adaptive smoothing for jitter reduction
8. **LatencyTracker**: Performance monitoring and logging

## Troubleshooting

### Camera not found
```bash
# List available cameras
python -c "import cv2; print([cv2.VideoCapture(i).read()[0] for i in range(5)])"

# Use specific camera
python python_mediapipe/main.py --camera 1
```

### High latency
- Use `--model-complexity 0` (Lite model)
- Enable `--skip-frames 2`
- Reduce resolution: `--width 640 --height 480`
- Ensure `--threaded-capture` is enabled

### Connection refused
- Check that Godot is running and listening on the correct port
- Verify `--host` and `--port` match Godot's configuration
- Check firewall settings

## License

Mozilla Public License 2.0 (MPL 2.0)

## Contributing

Contributions welcome! Please ensure:
- Code follows existing style
- Tests pass (`python python_mediapipe/test_filter.py`)
- New features are documented in this README
