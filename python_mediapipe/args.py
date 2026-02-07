import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="MediaPipe Pose Tracker")
    parser.add_argument("--camera", type=int, default=0, help="Camera device ID")
    parser.add_argument("--port", type=int, default=4242, help="UDP port")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="UDP host")
    parser.add_argument("--detection-confidence", type=float, default=0.5)
    parser.add_argument("--tracking-confidence", type=float, default=0.5)
    parser.add_argument("--model-complexity", type=int, default=1, choices=[0, 1, 2])
    parser.add_argument("--max-fps", type=int, default=30, help="Maximum capture FPS")
    return parser.parse_args()