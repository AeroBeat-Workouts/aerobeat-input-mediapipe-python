import argparse

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
    parser.add_argument("--binary-protocol", action="store_true", default=True,
                       help="Use binary serialization (faster than JSON)")
    parser.add_argument("--json-protocol", action="store_true",
                       help="Use JSON serialization (slower, for debugging)")
    parser.add_argument("--skip-frames", type=int, default=1,
                       help="Process every Nth frame (1 = all frames, 2 = every 2nd, etc.)")
    parser.add_argument("--threaded-capture", action="store_true", default=True,
                       help="Use threaded frame capture for lower latency")
    parser.add_argument("--no-threaded-capture", dest="threaded_capture", action="store_false",
                       help="Disable threaded frame capture")
    return parser.parse_args()
