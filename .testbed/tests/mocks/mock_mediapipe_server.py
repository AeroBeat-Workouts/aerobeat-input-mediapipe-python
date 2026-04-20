#!/usr/bin/env python3
"""Mock MediaPipe server for testing without real camera"""

import socket
import json
import time
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="Mock MediaPipe Server")
    parser.add_argument("--port", type=int, default=4242, help="UDP port")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="UDP host")
    parser.add_argument("--fps", type=int, default=30, help="Frames per second")
    return parser.parse_args()

def main():
    args = parse_args()
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    print(f"Mock MediaPipe server started - sending to {args.host}:{args.port}")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            # Generate fake landmark data
            payload = {
                "timestamp": time.time(),
                "landmarks": [
                    {"id": 0, "x": 0.5, "y": 0.5, "z": 0.0, "v": 0.99},  # Nose
                    {"id": 15, "x": 0.3, "y": 0.7, "z": 0.0, "v": 0.95}, # Left wrist
                    {"id": 16, "x": 0.7, "y": 0.7, "z": 0.0, "v": 0.95}, # Right wrist
                ]
            }
            
            try:
                sock.sendto(json.dumps(payload).encode(), (args.host, args.port))
            except Exception as e:
                print(f"Send error: {e}")
            
            time.sleep(1.0 / args.fps)
    except KeyboardInterrupt:
        print("\nMock server stopped")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
