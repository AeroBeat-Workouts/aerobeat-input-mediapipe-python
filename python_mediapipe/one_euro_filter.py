"""One-Euro filter implementation for motion tracking smoothing.

Based on the paper "A Simple Speed-based Low-pass Filter for Noisy Input in Interactive Systems"
by Casiez et al. (2012).

The One-Euro filter is an adaptive low-pass filter that reduces jitter while maintaining
responsiveness by dynamically adjusting the cutoff frequency based on the signal's speed.
"""

import numpy as np
from typing import List, Dict, Any, Optional


class OneEuroFilter:
    """Adaptive low-pass filter for motion tracking.
    
    The filter uses two exponential smoothing filters:
    - One for the derivative (speed estimation)
    - One for the value itself
    
    The cutoff frequency adapts based on the derivative: faster movements
    allow higher frequencies (less smoothing) while slow movements apply
    heavier smoothing to reduce jitter.
    """
    
    def __init__(self, min_cutoff: float = 1.0, beta: float = 0.0, d_cutoff: float = 1.0):
        """Initialize the One-Euro filter.
        
        Args:
            min_cutoff: Minimum cutoff frequency (Hz). Lower = smoother but more lag.
            beta: Speed coefficient. Higher = more responsive to fast movements.
            d_cutoff: Derivative cutoff frequency (Hz). Lower = smoother derivative.
        """
        self.min_cutoff = min_cutoff
        self.beta = beta
        self.d_cutoff = d_cutoff
        
        # State variables
        self.x_prev = None  # Previous filtered value
        self.dx_prev = None  # Previous derivative estimate
        self.t_prev = None  # Previous timestamp
        
        # Pre-compute smoothing constants (will be updated on first filter call)
        self._alpha_min = None
        self._alpha_d = None
    
    def _alpha_from_cutoff(self, cutoff: float, dt: float) -> float:
        """Compute smoothing factor from cutoff frequency and time delta.
        
        The exponential smoothing factor alpha is related to cutoff frequency by:
        alpha = 1 / (1 + tau/dt) where tau = 1/(2*pi*fc)
        """
        if dt <= 0:
            return 1.0
        tau = 1.0 / (2.0 * np.pi * cutoff)
        return 1.0 / (1.0 + tau / dt)
    
    def filter(self, x: float, t: float) -> float:
        """Apply the One-Euro filter to a value.
        
        Args:
            x: Current raw value
            t: Current timestamp (in seconds)
            
        Returns:
            Filtered value
        """
        # Initialize on first call
        if self.x_prev is None:
            self.x_prev = x
            self.dx_prev = 0.0
            self.t_prev = t
            return x
        
        # Compute time delta
        dt = t - self.t_prev
        if dt <= 0:
            dt = 1.0 / 60.0  # Assume 60fps if timestamps are invalid
        
        # Smooth the derivative (speed estimation)
        dx = (x - self.x_prev) / dt
        alpha_d = self._alpha_from_cutoff(self.d_cutoff, dt)
        dx_filtered = alpha_d * dx + (1.0 - alpha_d) * self.dx_prev
        
        # Compute adaptive cutoff based on speed
        cutoff = self.min_cutoff + self.beta * abs(dx_filtered)
        
        # Smooth the value with adaptive cutoff
        alpha = self._alpha_from_cutoff(cutoff, dt)
        x_filtered = alpha * x + (1.0 - alpha) * self.x_prev
        
        # Update state
        self.x_prev = x_filtered
        self.dx_prev = dx_filtered
        self.t_prev = t
        
        return x_filtered
    
    def reset(self):
        """Reset the filter state."""
        self.x_prev = None
        self.dx_prev = None
        self.t_prev = None


class LandmarkFilterBank:
    """Manages One-Euro filters for MediaPipe landmarks.
    
    MediaPipe has 33 landmarks, each with x, y, z coordinates.
    This class manages 99 individual One-Euro filters (33 landmarks × 3 coordinates).
    """
    
    # MediaPipe visibility threshold for landmark presence
    VISIBILITY_THRESHOLD = 0.5
    
    def __init__(self, num_landmarks: int = 33, min_cutoff: float = 1.0, 
                 beta: float = 0.0, d_cutoff: float = 1.0):
        """Initialize the filter bank.
        
        Args:
            num_landmarks: Number of landmarks to filter (default: 33 for MediaPipe)
            min_cutoff: Minimum cutoff frequency (Hz)
            beta: Speed coefficient
            d_cutoff: Derivative cutoff frequency (Hz)
        """
        self.num_landmarks = num_landmarks
        self.min_cutoff = min_cutoff
        self.beta = beta
        self.d_cutoff = d_cutoff
        
        # Create filters for each landmark and coordinate (x, y, z)
        # Structure: filters[landmark_id][coord] = OneEuroFilter
        # coord: 0=x, 1=y, 2=z
        self.filters = []
        self.prev_visibility = []  # Track previous visibility state
        
        for _ in range(num_landmarks):
            landmark_filters = [
                OneEuroFilter(min_cutoff, beta, d_cutoff),
                OneEuroFilter(min_cutoff, beta, d_cutoff),
                OneEuroFilter(min_cutoff, beta, d_cutoff)
            ]
            self.filters.append(landmark_filters)
            self.prev_visibility.append(0.0)
    
    def filter_landmarks(self, landmarks: List[Dict[str, Any]], 
                         timestamp: float) -> List[Dict[str, Any]]:
        """Apply filtering to all landmarks with visibility handling.
        
        Args:
            landmarks: List of landmark dicts with 'id', 'x', 'y', 'z', 'v' keys
            timestamp: Current timestamp in seconds
            
        Returns:
            List of filtered landmark dicts
        """
        filtered_landmarks = []
        
        # Track which landmarks were processed
        processed_ids = set()
        
        for lm in landmarks:
            lm_id = lm['id']
            if lm_id >= self.num_landmarks:
                continue  # Skip landmarks beyond our filter count
            
            processed_ids.add(lm_id)
            visibility = lm.get('v', 1.0)
            
            # Check if visibility changed significantly (lost or regained tracking)
            prev_visible = self.prev_visibility[lm_id] >= self.VISIBILITY_THRESHOLD
            curr_visible = visibility >= self.VISIBILITY_THRESHOLD
            
            # Reset filter if visibility state changed (tracking lost/regained)
            if prev_visible != curr_visible:
                for coord_filter in self.filters[lm_id]:
                    coord_filter.reset()
            
            # Update visibility tracking
            self.prev_visibility[lm_id] = visibility
            
            # Only filter if landmark is visible
            if curr_visible:
                x_filtered = self.filters[lm_id][0].filter(lm['x'], timestamp)
                y_filtered = self.filters[lm_id][1].filter(lm['y'], timestamp)
                z_filtered = self.filters[lm_id][2].filter(lm['z'], timestamp)
            else:
                # For invisible landmarks, pass through raw values but keep filter state
                # This prevents jumps when visibility returns
                x_filtered = lm['x']
                y_filtered = lm['y']
                z_filtered = lm['z']
            
            filtered_landmarks.append({
                'id': lm_id,
                'x': x_filtered,
                'y': y_filtered,
                'z': z_filtered,
                'v': visibility
            })
        
        return filtered_landmarks
    
    def reset_all(self):
        """Reset all filters in the bank."""
        for landmark_filters in self.filters:
            for coord_filter in landmark_filters:
                coord_filter.reset()
        self.prev_visibility = [0.0] * self.num_landmarks
    
    def reset_landmark(self, landmark_id: int):
        """Reset filters for a specific landmark.
        
        Args:
            landmark_id: Index of the landmark to reset
        """
        if 0 <= landmark_id < self.num_landmarks:
            for coord_filter in self.filters[landmark_id]:
                coord_filter.reset()
            self.prev_visibility[landmark_id] = 0.0
    
    def update_params(self, min_cutoff: Optional[float] = None, 
                      beta: Optional[float] = None,
                      d_cutoff: Optional[float] = None):
        """Update filter parameters dynamically.
        
        Note: This resets all filters since parameter changes invalidate
        the internal state.
        
        Args:
            min_cutoff: New minimum cutoff frequency
            beta: New speed coefficient
            d_cutoff: New derivative cutoff
        """
        if min_cutoff is not None:
            self.min_cutoff = min_cutoff
        if beta is not None:
            self.beta = beta
        if d_cutoff is not None:
            self.d_cutoff = d_cutoff
        
        # Recreate all filters with new parameters
        self.filters = []
        for _ in range(self.num_landmarks):
            landmark_filters = [
                OneEuroFilter(self.min_cutoff, self.beta, self.d_cutoff),
                OneEuroFilter(self.min_cutoff, self.beta, self.d_cutoff),
                OneEuroFilter(self.min_cutoff, self.beta, self.d_cutoff)
            ]
            self.filters.append(landmark_filters)
        
        self.prev_visibility = [0.0] * self.num_landmarks


# Preset configurations for common use cases
FILTER_PRESETS = {
    "responsive": {"min_cutoff": 2.0, "beta": 0.01, "d_cutoff": 1.0},
    "balanced": {"min_cutoff": 1.0, "beta": 0.005, "d_cutoff": 1.0},
    "smooth": {"min_cutoff": 0.5, "beta": 0.002, "d_cutoff": 1.0}
}


def get_preset_params(preset_name: str) -> Dict[str, float]:
    """Get filter parameters for a named preset.
    
    Args:
        preset_name: Name of the preset ('responsive', 'balanced', 'smooth')
        
    Returns:
        Dictionary of filter parameters
        
    Raises:
        ValueError: If preset name is not recognized
    """
    if preset_name not in FILTER_PRESETS:
        raise ValueError(f"Unknown preset '{preset_name}'. "
                        f"Available: {list(FILTER_PRESETS.keys())}")
    return FILTER_PRESETS[preset_name].copy()
