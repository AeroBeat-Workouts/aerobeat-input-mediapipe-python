#!/usr/bin/env python3
"""MediaPipe Pose Tracker - UDP Sidecar for Godot"""

import signal
import sys
import socket
import json
import time
from args import parse_args

try:
    import cv2
    import mediapipe as mp
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

args = parse_args()

# Global flag for graceful shutdown
_running = True

def signal_handler(sig, frame):
    global _running
    print("\nShutting down gracefully...")
    _running = False

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def main():
    # Initialize UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # Initialize MediaPipe
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        min_detection_confidence=args.detection_confidence,
        min_tracking_confidence=args.tracking_confidence,
        model_complexity=args.model_complexity
    )
    
    # Initialize camera
    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print(f"Error: Could not open camera {args.camera}")
        sys.exit(1)
    
    print(f"MediaPipe started - Camera: {args.camera}, UDP: {args.host}:{args.port}")
    
    while _running:
        ret, frame = cap.read()
        if not ret:
            print("Warning: Failed to capture frame")
            continue
        
        # Process frame
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(frame_rgb)
        
        # Extract landmarks
        landmarks = []
        if results.pose_landmarks:
            for idx, landmark in enumerate(results.pose_landmarks.landmark):
                landmarks.append({
                    "id": idx,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "v": landmark.visibility
                })
        
        # Send via UDP
        payload = {
            "timestamp": time.time(),
            "landmarks": landmarks
        }
        
        try:
            sock.sendto(json.dumps(payload).encode(), (args.host, args.port))
        except Exception as e:
            print(f"UDP send error: {e}")
        
        # Cap FPS
        time.sleep(1.0 / args.max_fps)
    
    # Cleanup
    cap.release()
    pose.close()
    sock.close()
    print("MediaPipe stopped")

if __name__ == "__main__":
    main()