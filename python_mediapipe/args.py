import argparse
from one_euro_filter import FILTER_PRESETS

def parse_args():
    parser = argparse.ArgumentParser(description="MediaPipe Pose Tracker")
    parser.add_argument("--camera", type=int, default=0, help="Camera device ID")
    parser.add_argument("--port", type=int, default=4242, help="UDP port")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="UDP host")
    parser.add_argument("--detection-confidence", type=float, default=0.3,
                       help="Detection confidence threshold (lower = faster)")
    parser.add_argument("--tracking-confidence", type=float, default=0.3,
                       help="Tracking confidence threshold (lower = faster)")
    parser.add_argument("--model-complexity", type=int, default=0, choices=[0, 1, 2],
                       help="Model complexity: 0=Lite (fastest), 1=Full, 2=Heavy")
    parser.add_argument("--max-fps", type=int, default=60, help="Maximum capture FPS")
    parser.add_argument("--width", type=int, default=640, help="Camera width")
    parser.add_argument("--height", type=int, default=480, help="Camera height")
    parser.add_argument("--binary-protocol", action="store_true",
                       help="Use binary serialization (faster than JSON)")
    parser.add_argument("--json-protocol", action="store_true", default=True,
                       help="Use JSON serialization (slower, for debugging)")
    parser.add_argument("--skip-frames", type=int, default=1,
                       help="Process every Nth frame (1 = all frames, 2 = every 2nd, etc.)")
    parser.add_argument("--threaded-capture", action="store_true", default=True,
                       help="Use threaded frame capture for lower latency")
    parser.add_argument("--no-threaded-capture", dest="threaded_capture", action="store_false",
                       help="Disable threaded frame capture")
    parser.add_argument("--udp-buffer-size", type=int, default=4096,
                       help="UDP socket buffer size in bytes (default: 4096, lower = lower latency)")
    
    # One-Euro filter arguments
    parser.add_argument("--use-filter", action="store_true", default=True,
                       help="Enable One-Euro filtering for landmark smoothing (default: enabled)")
    parser.add_argument("--no-filter", dest="use_filter", action="store_false",
                       help="Disable One-Euro filtering")
    parser.add_argument("--filter-preset", type=str, default="balanced",
                       choices=list(FILTER_PRESETS.keys()),
                       help=f"Filter tuning preset ({', '.join(FILTER_PRESETS.keys())})")
    parser.add_argument("--filter-min-cutoff", type=float, default=None,
                       help="Minimum cutoff frequency in Hz (overrides preset, lower = smoother)")
    parser.add_argument("--filter-beta", type=float, default=None,
                       help="Speed coefficient (overrides preset, higher = more responsive)")
    parser.add_argument("--filter-d-cutoff", type=float, default=None,
                       help="Derivative cutoff frequency in Hz (default: 1.0)")
    
    # Frame Preprocessing - resize frame before inference
    parser.add_argument("--preprocess-size", type=int, default=0,
                       help="Resize frame to this height before inference, 0=disable (default: 0)")
    
    # UDP Batching - batch multiple frames per packet
    parser.add_argument("--udp-batch-size", type=int, default=1,
                       help="Number of frames to batch per UDP packet, 1-10 (default: 1)")
    
    # Predictive ROI Tracking
    parser.add_argument("--use-roi", action="store_true",
                       help="Enable Predictive ROI tracking for focused inference")
    parser.add_argument("--roi-size", type=int, default=320,
                       help="ROI target height in pixels (default: 320)")
    parser.add_argument("--roi-padding", type=int, default=50,
                       help="Padding around detected person in pixels (default: 50)")
    
    # MJPEG Camera Streaming
    parser.add_argument("--stream-camera", action="store_true",
                       help="Enable MJPEG camera streaming to Godot (default: disabled)")
    parser.add_argument("--stream-port", type=int, default=4243,
                       help="HTTP port for camera stream (default: 4243)")
    parser.add_argument("--stream-quality", type=int, default=50,
                       help="JPEG quality for stream 0-100 (default: 50, lower = faster)")
    
    # Debug Window
    parser.add_argument("--show-window", action="store_true",
                       help="Show OpenCV debug window with pose overlay (default: disabled)")
    parser.add_argument("--window-scale", type=float, default=1.0,
                       help="Scale factor for debug window (default: 1.0)")
    
    return parser.parse_args()
