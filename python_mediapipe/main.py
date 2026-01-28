import cv2
import mediapipe as mp
import socket
import json
import time
import sys

# --- Configuration ---
# Ensure this port matches the one defined in '/src/strategies/strategy_mediapipe.gd'
UDP_IP = "127.0.0.1"
UDP_PORT = 4242

def main():
    # 1. Setup UDP Socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print(f"Target: {UDP_IP}:{UDP_PORT}")

    # 2. Setup MediaPipe Pose
    mp_pose = mp.solutions.pose
    # model_complexity=1 is a good balance between speed and accuracy.
    # Use 2 for higher accuracy (slower), 0 for speed.
    pose = mp_pose.Pose(
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
        model_complexity=1
    )

    # 3. Setup Video Capture
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open video capture device.")
        sys.exit(1)

    print("MediaPipe Pose tracking started. Press 'q' to exit.")

    try:
        while cap.isOpened():
            success, image = cap.read()
            if not success:
                print("Ignoring empty camera frame.")
                continue

            # MediaPipe requires RGB, OpenCV provides BGR
            image.flags.writeable = False
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Perform inference
            results = pose.process(image_rgb)

            # 4. Extract and Send Data
            if results.pose_landmarks:
                landmark_list = []
                # MediaPipe Pose returns 33 landmarks (0-32)
                for i, lm in enumerate(results.pose_landmarks.landmark):
                    landmark_list.append({
                        "id": i,
                        "x": lm.x,
                        "y": lm.y,
                        "z": lm.z,
                        "v": lm.visibility # Visibility score
                    })

                payload = {
                    "timestamp": time.time(),
                    "landmarks": landmark_list
                }

                # Send JSON string encoded as bytes
                sock.sendto(json.dumps(payload).encode('utf-8'), (UDP_IP, UDP_PORT))

            # Optional: Visualization (press 'q' to quit)
            cv2.imshow('AeroBeat Input - MediaPipe', cv2.flip(image, 1))
            if cv2.waitKey(5) & 0xFF == ord('q'):
                break

    finally:
        cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    main()