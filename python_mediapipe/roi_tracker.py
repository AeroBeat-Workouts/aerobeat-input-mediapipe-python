"""Predictive ROI Tracker - Smart region-of-interest tracking for AeroBeat"""

from collections import deque
import numpy as np


class PredictiveROITracker:
    """Smart ROI that predicts player movement"""
    
    def __init__(self, 
                 target_size=320, 
                 padding=50,
                 velocity_window=5,
                 expand_threshold=0.7):
        """
        Args:
            target_size: ROI height in pixels
            padding: Pixels around detected person
            velocity_window: Frames to track for velocity
            expand_threshold: Confidence below which we expand ROI
        """
        self.target_size = target_size
        self.padding = padding
        self.velocity_window = velocity_window
        self.expand_threshold = expand_threshold
        
        # State
        self.roi = None  # (x, y, w, h)
        self.positions = deque(maxlen=velocity_window)
        self.velocities = deque(maxlen=velocity_window)
        self.lost_frames = 0
        self.max_lost = 3
        
    def update(self, landmarks, frame_shape):
        """Update ROI based on landmarks"""
        if landmarks:
            # Calculate center from landmarks
            center_x = np.mean([lm['x'] * frame_shape[1] for lm in landmarks])
            center_y = np.mean([lm['y'] * frame_shape[0] for lm in landmarks])
            
            # Update velocity tracking
            if self.positions:
                last_x, last_y = self.positions[-1]
                vx = center_x - last_x
                vy = center_y - last_y
                self.velocities.append((vx, vy))
            
            self.positions.append((center_x, center_y))
            self.lost_frames = 0
            
            # Predict next position
            if len(self.velocities) >= 2:
                avg_vx = np.mean([v[0] for v in self.velocities])
                avg_vy = np.mean([v[1] for v in self.velocities])
                predicted_x = center_x + avg_vx
                predicted_y = center_y + avg_vy
            else:
                predicted_x, predicted_y = center_x, center_y
            
            # Calculate ROI around predicted position
            aspect = frame_shape[1] / frame_shape[0]
            roi_w = int(self.target_size * aspect)
            roi_h = self.target_size
            
            x1 = max(0, int(predicted_x - roi_w/2))
            y1 = max(0, int(predicted_y - roi_h/2))
            x2 = min(frame_shape[1], x1 + roi_w)
            y2 = min(frame_shape[0], y1 + roi_h)
            
            self.roi = (x1, y1, x2 - x1, y2 - y1)
            
        else:
            # Lost tracking - predict from last known velocity
            self.lost_frames += 1
            
            if self.lost_frames <= self.max_lost and self.positions and self.velocities:
                # Predict where they went
                last_x, last_y = self.positions[-1]
                avg_vx = np.mean([v[0] for v in self.velocities])
                avg_vy = np.mean([v[1] for v in self.velocities])
                
                predicted_x = last_x + avg_vx * self.lost_frames
                predicted_y = last_y + avg_vy * self.lost_frames
                
                # Expand ROI for search
                aspect = frame_shape[1] / frame_shape[0]
                roi_w = int(self.target_size * aspect * 1.5)  # 50% larger
                roi_h = int(self.target_size * 1.5)
                
                x1 = max(0, int(predicted_x - roi_w/2))
                y1 = max(0, int(predicted_y - roi_h/2))
                x2 = min(frame_shape[1], x1 + roi_w)
                y2 = min(frame_shape[0], y1 + roi_h)
                
                self.roi = (x1, y1, x2 - x1, y2 - y1)
            else:
                # Give up, use full frame
                self.roi = (0, 0, frame_shape[1], frame_shape[0])
                self.positions.clear()
                self.velocities.clear()
    
    def crop_frame(self, frame):
        """Crop frame to ROI"""
        if self.roi is None:
            return frame, (1.0, 1.0), (0, 0)
        
        x, y, w, h = self.roi
        cropped = frame[y:y+h, x:x+w]
        
        # Calculate scale factor for landmarks
        scale_y = cropped.shape[0] / frame.shape[0]
        scale_x = cropped.shape[1] / frame.shape[1]
        
        return cropped, (scale_x, scale_x), (x, y)
    
    def adjust_landmarks(self, landmarks, scale, offset):
        """Adjust landmark coordinates back to original frame"""
        scale_x, scale_y = scale
        offset_x, offset_y = offset
        
        for lm in landmarks:
            # Scale landmarks and add offset in normalized coordinates
            lm['x'] = (lm['x'] * scale_x) + (offset_x / frame.shape[1] if 'frame' in dir() else offset_x / 1000)
            lm['y'] = (lm['y'] * scale_y) + (offset_y / frame.shape[0] if 'frame' in dir() else offset_y / 1000)
        
        return landmarks
