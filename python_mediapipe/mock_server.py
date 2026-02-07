#!/usr/bin/env python3
"""Mock MediaPipe Server - Sends fake landmark data for testing without camera"""

import socket
import json
import time
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="Mock MediaPipe Server for testing")
    parser.add_argument("--host", default="127.0.0.1", help="UDP host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=4242, help="UDP port (default: 4242)")
    parser.add_argument("--fps", type=float, default=30.0, help="Frames per second (default: 30)")
    parser.add_argument("--test-duration", type=float, default=0, 
                        help="Test duration in seconds (0 = infinite)")
    return parser.parse_args()

def create_mock_landmarks():
    """Create a set of fake MediaPipe pose landmarks"""
    landmarks = []
    
    # MediaPipe Pose has 33 landmarks
    for i in range(33):
        # Create a simple waving motion pattern
        x = 0.3 + (i * 0.02)  # Spread across screen
        y = 0.4 + 0.1 * (1 if i % 2 == 0 else -1)  # Slight variation
        z = 0.0
        visibility = 0.95
        
        landmarks.append({
            "id": i,
            "x": x,
            "y": y,
            "z": z,
            "v": visibility
        })
    
    return landmarks

def main():
    args = parse_args()
    
    # Initialize UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    print(f"Mock MediaPipe Server started")
    print(f"  Host: {args.host}")
    print(f"  Port: {args.port}")
    print(f"  FPS: {args.fps}")
    print(f"  Duration: {'infinite' if args.test_duration == 0 else args.test_duration + 's'}")
    print(f"  Press Ctrl+C to stop")
    print()
    
    frame_count = 0
    start_time = time.time()
    
    try:
        while True:
            # Check duration
            if args.test_duration > 0 and (time.time() - start_time) >= args.test_duration:
                print(f"\nTest duration reached ({args.test_duration}s)")
                break
            
            # Create mock landmarks with slight animation
            landmarks = create_mock_landmarks()
            
            # Add some motion to make it look realistic
            wave_offset = 0.05 * (1 if frame_count % 60 < 30 else -1)
            for lm in landmarks:
                if lm["id"] in [15, 16]:  # Wrists
                    lm["y"] += wave_offset
            
            # Send via UDP
            payload = {
                "timestamp": time.time(),
                "landmarks": landmarks
            }
            
            try:
                sock.sendto(json.dumps(payload).encode(), (args.host, args.port))
                frame_count += 1
                
                if frame_count % 30 == 0:
                    elapsed = time.time() - start_time
                    fps = frame_count / elapsed if elapsed > 0 else 0
                    print(f"Sent {frame_count} frames ({fps:.1f} FPS)", end="\r")
                    
            except Exception as e:
                print(f"UDP send error: {e}")
            
            # Cap FPS
            time.sleep(1.0 / args.fps)
            
    except KeyboardInterrupt:
        print("\n\nShutting down...")
    
    finally:
        sock.close()
        elapsed = time.time() - start_time
        print(f"Mock server stopped after {frame_count} frames ({elapsed:.1f}s)")

if __name__ == "__main__":
    main()
