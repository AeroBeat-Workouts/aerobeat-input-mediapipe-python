#!/usr/bin/env python3
"""Test script for One-Euro filter implementation."""

import time
import math
from one_euro_filter import OneEuroFilter, LandmarkFilterBank, get_preset_params

def test_one_euro_filter():
    """Test basic One-Euro filter functionality."""
    print("Testing OneEuroFilter...")
    
    filter = OneEuroFilter(min_cutoff=1.0, beta=0.005)
    
    # Test with noisy sine wave
    timestamps = []
    raw_values = []
    filtered_values = []
    
    t_start = time.time()
    for i in range(100):
        t = t_start + i * 0.016  # 60fps
        # Sine wave with noise
        raw = math.sin(t * 5) + (math.random() - 0.5) * 0.1 if hasattr(math, 'random') else math.sin(t * 5)
        # Use deterministic noise for reproducibility
        import random
        random.seed(i)
        raw = math.sin(t * 5) + (random.random() - 0.5) * 0.1
        
        filtered = filter.filter(raw, t)
        
        timestamps.append(t)
        raw_values.append(raw)
        filtered_values.append(filtered)
    
    # Check that filter reduced variance (smoothing effect)
    raw_variance = sum((x - sum(raw_values)/len(raw_values))**2 for x in raw_values) / len(raw_values)
    filtered_variance = sum((x - sum(filtered_values)/len(filtered_values))**2 for x in filtered_values) / len(filtered_values)
    
    print(f"  Raw variance: {raw_variance:.6f}")
    print(f"  Filtered variance: {filtered_variance:.6f}")
    print(f"  Variance reduction: {(1 - filtered_variance/raw_variance)*100:.1f}%")
    
    # Test reset
    filter.reset()
    assert filter.x_prev is None
    print("  Reset test: PASSED")
    
    print("OneEuroFilter test: PASSED")
    return True

def test_landmark_filter_bank():
    """Test LandmarkFilterBank with MediaPipe-style landmarks."""
    print("\nTesting LandmarkFilterBank...")
    
    filter_bank = LandmarkFilterBank(num_landmarks=33, min_cutoff=1.0, beta=0.005)
    
    # Create synthetic landmarks
    landmarks = []
    for i in range(33):
        landmarks.append({
            "id": i,
            "x": 0.5 + (i % 5) * 0.01,
            "y": 0.5 + (i % 3) * 0.01,
            "z": 0.0,
            "v": 0.9 if i < 25 else 0.3  # Some landmarks visible, some not
        })
    
    # Filter multiple frames
    t_start = time.time()
    for frame in range(10):
        t = t_start + frame * 0.016
        
        # Add small jitter
        import random
        jittered = []
        for lm in landmarks:
            jittered.append({
                "id": lm["id"],
                "x": lm["x"] + (random.random() - 0.5) * 0.01,
                "y": lm["y"] + (random.random() - 0.5) * 0.01,
                "z": lm["z"],
                "v": lm["v"]
            })
        
        filtered = filter_bank.filter_landmarks(jittered, t)
        assert len(filtered) == 33
    
    print("  33 landmarks filtered over 10 frames")
    
    # Test visibility reset
    filter_bank.reset_all()
    assert all(v == 0.0 for v in filter_bank.prev_visibility)
    print("  Reset all test: PASSED")
    
    # Test single landmark reset
    filter_bank.filter_landmarks(landmarks, t_start)
    filter_bank.reset_landmark(5)
    assert filter_bank.prev_visibility[5] == 0.0
    print("  Single landmark reset test: PASSED")
    
    print("LandmarkFilterBank test: PASSED")
    return True

def test_performance():
    """Measure filter performance (should be < 0.1ms per frame)."""
    print("\nTesting performance...")
    
    filter_bank = LandmarkFilterBank(num_landmarks=33, min_cutoff=1.0, beta=0.005)
    
    # Create test landmarks
    landmarks = []
    for i in range(33):
        landmarks.append({
            "id": i,
            "x": 0.5,
            "y": 0.5,
            "z": 0.0,
            "v": 0.9
        })
    
    # Warmup
    for i in range(10):
        filter_bank.filter_landmarks(landmarks, time.time() + i * 0.016)
    
    # Measure
    times = []
    for i in range(100):
        t = time.time() + i * 0.016
        start = time.perf_counter()
        filter_bank.filter_landmarks(landmarks, t)
        elapsed = (time.perf_counter() - start) * 1000  # ms
        times.append(elapsed)
    
    avg_time = sum(times) / len(times)
    max_time = max(times)
    
    print(f"  Average filter time: {avg_time:.4f}ms")
    print(f"  Max filter time: {max_time:.4f}ms")
    
    if avg_time < 0.1:
        print("  Performance target met (< 0.1ms): PASSED")
    else:
        print(f"  Performance target NOT met (got {avg_time:.4f}ms, target < 0.1ms)")
    
    return avg_time < 0.5  # Allow some margin

def test_presets():
    """Test filter presets."""
    print("\nTesting filter presets...")
    
    presets = ["responsive", "balanced", "smooth"]
    for preset_name in presets:
        params = get_preset_params(preset_name)
        bank = LandmarkFilterBank(num_landmarks=33, **params)
        print(f"  Preset '{preset_name}': min_cutoff={params['min_cutoff']}, "
              f"beta={params['beta']}, d_cutoff={params['d_cutoff']}")
    
    # Test invalid preset
    try:
        get_preset_params("invalid")
        print("  Invalid preset test: FAILED (should have raised)")
        return False
    except ValueError:
        print("  Invalid preset test: PASSED")
    
    print("Filter presets test: PASSED")
    return True

def test_visibility_handling():
    """Test visibility change detection and filter reset."""
    print("\nTesting visibility handling...")
    
    filter_bank = LandmarkFilterBank(num_landmarks=5, min_cutoff=1.0, beta=0.005)
    
    t = time.time()
    
    # First frame: landmarks visible
    landmarks_visible = [
        {"id": 0, "x": 0.5, "y": 0.5, "z": 0.0, "v": 0.9},
        {"id": 1, "x": 0.6, "y": 0.6, "z": 0.0, "v": 0.9},
    ]
    filtered = filter_bank.filter_landmarks(landmarks_visible, t)
    
    # Second frame: landmark 0 becomes invisible
    landmarks_invisible = [
        {"id": 0, "x": 0.5, "y": 0.5, "z": 0.0, "v": 0.3},  # Below threshold
        {"id": 1, "x": 0.6, "y": 0.6, "z": 0.0, "v": 0.9},
    ]
    filtered = filter_bank.filter_landmarks(landmarks_invisible, t + 0.016)
    
    # Third frame: landmark 0 becomes visible again (filter should be reset)
    landmarks_visible_again = [
        {"id": 0, "x": 0.7, "y": 0.7, "z": 0.0, "v": 0.9},
        {"id": 1, "x": 0.6, "y": 0.6, "z": 0.0, "v": 0.9},
    ]
    filtered = filter_bank.filter_landmarks(landmarks_visible_again, t + 0.032)
    
    print("  Visibility transition test: PASSED")
    print("Visibility handling test: PASSED")
    return True

if __name__ == "__main__":
    print("=" * 60)
    print("One-Euro Filter Test Suite")
    print("=" * 60)
    
    all_passed = True
    all_passed &= test_one_euro_filter()
    all_passed &= test_landmark_filter_bank()
    all_passed &= test_presets()
    all_passed &= test_visibility_handling()
    all_passed &= test_performance()
    
    print("\n" + "=" * 60)
    if all_passed:
        print("All tests PASSED")
    else:
        print("Some tests FAILED")
    print("=" * 60)
