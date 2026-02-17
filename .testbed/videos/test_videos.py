"""
Video Input Module for Automated Testing

Provides OpenCV VideoCapture wrapper with multiple playback modes
for deterministic and real-time testing scenarios.

This script is located in .testbed/videos/ and can test videos in this folder
or serve as a utility for the Python sidecar.
"""

import cv2
import time
import sys
from pathlib import Path
from enum import Enum
from dataclasses import dataclass
from typing import Optional, Iterator, List

# Add python_mediapipe to path for imports
# This script is in: .testbed/videos/
# python_mediapipe is at: ../../python_mediapipe/
PYTHON_MEDIAPIPE_PATH = Path(__file__).parent.parent.parent / "python_mediapipe"
if PYTHON_MEDIAPIPE_PATH.exists():
    sys.path.insert(0, str(PYTHON_MEDIAPIPE_PATH))


class PlaybackMode(Enum):
    """Video playback modes for different testing scenarios."""
    FRAME_ACCURATE = "frame_accurate"  # Process as fast as possible
    REALTIME = "realtime"              # Enforce original FPS timing
    LOOP = "loop"                      # Loop video continuously


@dataclass
class VideoMetadata:
    """Video file metadata extracted from OpenCV."""
    path: str
    fps: float
    frame_count: int
    width: int
    height: int
    duration_seconds: float
    
    @classmethod
    def from_capture(cls, path: str, cap: cv2.VideoCapture) -> "VideoMetadata":
        """Extract metadata from an OpenCV VideoCapture object."""
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        duration = frame_count / fps if fps > 0 else 0.0
        
        return cls(
            path=path,
            fps=fps,
            frame_count=frame_count,
            width=width,
            height=height,
            duration_seconds=duration
        )


@dataclass
class Frame:
    """A video frame with metadata."""
    number: int
    image: any  # OpenCV image (numpy array)
    timestamp_ms: float
    is_keyframe: bool = False


class VideoInput:
    """
    OpenCV VideoCapture wrapper for testing.
    
    Supports multiple playback modes:
    - frame_accurate: Process every frame as fast as possible (deterministic)
    - realtime: Enforce original FPS timing (performance testing)
    - loop: Continuously loop the video
    """
    
    def __init__(self, video_path: str, mode: PlaybackMode = PlaybackMode.FRAME_ACCURATE):
        """
        Initialize video input.
        
        Args:
            video_path: Path to the video file
            mode: Playback mode (frame_accurate, realtime, loop)
        """
        self.video_path = video_path
        self.mode = mode
        self._cap: Optional[cv2.VideoCapture] = None
        self._metadata: Optional[VideoMetadata] = None
        self._frame_number = 0
        self._start_time: Optional[float] = None
        self._is_running = False
        
    def open(self) -> bool:
        """
        Open the video file and extract metadata.
        
        Returns:
            True if successful, False otherwise
        """
        self._cap = cv2.VideoCapture(self.video_path)
        
        if not self._cap.isOpened():
            raise ValueError(f"Failed to open video: {self.video_path}")
        
        self._metadata = VideoMetadata.from_capture(self.video_path, self._cap)
        self._frame_number = 0
        self._start_time = None
        self._is_running = True
        
        return True
    
    def close(self):
        """Release video capture resources."""
        self._is_running = False
        if self._cap:
            self._cap.release()
            self._cap = None
    
    def __enter__(self):
        """Context manager entry."""
        self.open()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
    
    @property
    def metadata(self) -> Optional[VideoMetadata]:
        """Get video metadata."""
        return self._metadata
    
    def read_frame(self) -> Optional[Frame]:
        """
        Read the next frame from the video.
        
        Returns:
            Frame object or None if end of video (or error)
        """
        if not self._is_running or not self._cap:
            return None
        
        # Handle looping mode
        if self.mode == PlaybackMode.LOOP:
            if self._frame_number >= self._metadata.frame_count:
                self._cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                self._frame_number = 0
                self._start_time = None
        
        # Read frame
        ret, image = self._cap.read()
        
        if not ret:
            return None
        
        # Calculate timestamp
        if self._start_time is None:
            self._start_time = time.time()
        
        timestamp_ms = (time.time() - self._start_time) * 1000
        
        # Handle realtime mode - enforce FPS timing
        if self.mode == PlaybackMode.REALTIME and self._metadata:
            expected_time_ms = (self._frame_number / self._metadata.fps) * 1000
            sleep_time = (expected_time_ms - timestamp_ms) / 1000.0
            if sleep_time > 0:
                time.sleep(sleep_time)
                timestamp_ms = expected_time_ms
        
        frame = Frame(
            number=self._frame_number,
            image=image,
            timestamp_ms=timestamp_ms
        )
        
        self._frame_number += 1
        return frame
    
    def frames(self) -> Iterator[Frame]:
        """
        Iterator that yields all frames from the video.
        
        Yields:
            Frame objects until end of video
        """
        while self._is_running:
            frame = self.read_frame()
            if frame is None:
                break
            yield frame
    
    def seek(self, frame_number: int) -> bool:
        """
        Seek to a specific frame number.
        
        Args:
            frame_number: Frame index to seek to
            
        Returns:
            True if successful
        """
        if not self._cap:
            return False
        
        success = self._cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        if success:
            self._frame_number = frame_number
        return success
    
    def get_progress(self) -> float:
        """
        Get current playback progress as percentage.
        
        Returns:
            Progress from 0.0 to 100.0
        """
        if not self._metadata or self._metadata.frame_count == 0:
            return 0.0
        return (self._frame_number / self._metadata.frame_count) * 100.0


def discover_test_videos(directory: Path = None) -> List[Path]:
    """
    Discover test video files in the specified directory.
    
    Args:
        directory: Directory to search (defaults to script's directory)
        
    Returns:
        List of video file paths
    """
    if directory is None:
        directory = Path(__file__).parent
    
    video_extensions = {".mp4", ".avi", ".mov", ".mkv", ".webm"}
    videos = []
    
    for ext in video_extensions:
        videos.extend(directory.glob(f"*{ext}"))
    
    return sorted(videos)


def test_video_input():
    """Test video input with a specific file or all discovered test videos."""
    
    # If video path provided as argument, test that specific video
    if len(sys.argv) >= 2:
        video_path = sys.argv[1]
        videos = [Path(video_path)]
    else:
        # Auto-discover test videos in this directory
        videos = discover_test_videos()
        if not videos:
            print("No test videos found in:", Path(__file__).parent)
            print("Usage: python test_videos.py [<video_file>]")
            sys.exit(1)
        print(f"Discovered {len(videos)} test video(s)")
    
    for video_path in videos:
        print(f"\n{'='*60}")
        print(f"Testing: {video_path.name}")
        print(f"{'='*60}")
        
        try:
            with VideoInput(str(video_path), mode=PlaybackMode.FRAME_ACCURATE) as video:
                print(f"\nVideo Metadata:")
                print(f"  Path: {video.metadata.path}")
                print(f"  Resolution: {video.metadata.width}x{video.metadata.height}")
                print(f"  FPS: {video.metadata.fps:.2f}")
                print(f"  Frame Count: {video.metadata.frame_count}")
                print(f"  Duration: {video.metadata.duration_seconds:.2f}s")
                
                print(f"\nReading frames...")
                frame_count = 0
                for frame in video.frames():
                    frame_count += 1
                    if frame_count % 30 == 0:
                        progress = video.get_progress()
                        print(f"  Frame {frame.number} @ {frame.timestamp_ms:.1f}ms ({progress:.1f}%)")
                
                print(f"\n✓ Total frames read: {frame_count}")
                
        except Exception as e:
            print(f"\n✗ Error testing {video_path.name}: {e}")
            continue
    
    print(f"\n{'='*60}")
    print("Video testing complete!")
    print(f"{'='*60}")


def test_with_sidecar_integration():
    """
    Test integration with the Python sidecar.
    
    This demonstrates how to use VideoInput to feed frames to the
    MediaPipe Python sidecar for testing without a live camera.
    """
    try:
        # Try to import from python_mediapipe
        from main import MediaPipeServer  # Example import
        print("Python sidecar modules available!")
        print("You can now test with: python test_videos.py <video_file>")
        print("And modify this function to feed frames to the sidecar.")
    except ImportError as e:
        print(f"Python sidecar modules not available: {e}")
        print("VideoInput can still be used standalone for video testing.")


if __name__ == "__main__":
    test_video_input()