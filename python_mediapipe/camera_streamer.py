#!/usr/bin/env python3
"""MJPEG Camera Streamer - HTTP server for serving camera feed to Godot"""

import threading
import socket
import time
import cv2
import numpy as np
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn


class MJPEGHTTPHandler(BaseHTTPRequestHandler):
    """HTTP handler for MJPEG streaming"""
    
    # Shared frame state (set by MJPEGStreamer)
    frame_buffer = None
    frame_sequence = 0
    frame_lock = threading.Lock()
    frame_ready = threading.Condition(frame_lock)
    
    # Stream settings
    boundary = '--frame-boundary'
    content_type = 'multipart/x-mixed-replace; boundary=' + boundary
    jpeg_quality = 50  # Reduced from 70 for faster encoding + lower bandwidth
    
    def log_message(self, format, *args):
        """Suppress default HTTP logging to reduce noise"""
        pass
    
    def do_GET(self):
        """Handle GET requests - serve MJPEG stream or snapshot"""
        if self.path == '/camera' or self.path == '/stream':
            self._serve_mjpeg_stream()
        elif self.path == '/snapshot':
            self._serve_snapshot()
        elif self.path == '/':
            self._serve_status()
        else:
            self.send_error(404, "Not found")
    
    def _serve_mjpeg_stream(self):
        """Serve continuous MJPEG stream"""
        self.send_response(200)
        self.send_header('Content-Type', self.content_type)
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.end_headers()
        
        # Disable Nagle's algorithm for low-latency streaming
        if hasattr(self.request, 'setsockopt'):
            try:
                self.request.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            except (OSError, AttributeError):
                pass  # Some socket types don't support this
        
        last_sent_sequence = -1
        placeholder_sent = False
        
        try:
            while True:
                with self.frame_ready:
                    while self.frame_buffer is not None and self.frame_sequence == last_sent_sequence:
                        self.frame_ready.wait(timeout=1.0)
                    
                    if self.frame_buffer is None:
                        if placeholder_sent:
                            self.frame_ready.wait(timeout=1.0)
                            continue
                        frame_data = self._create_placeholder_frame()
                        placeholder_sent = True
                    else:
                        frame_data = self.frame_buffer
                        last_sent_sequence = self.frame_sequence
                        placeholder_sent = False
                
                # Send frame
                self.wfile.write(f'{self.boundary}\r\n'.encode())
                self.wfile.write(b'Content-Type: image/jpeg\r\n')
                self.wfile.write(f'Content-Length: {len(frame_data)}\r\n\r\n'.encode())
                self.wfile.write(frame_data)
                self.wfile.write(b'\r\n')
                
        except (BrokenPipeError, ConnectionResetError):
            # Client disconnected
            pass
        except Exception as e:
            print(f"[MJPEG] Stream error: {e}")
    
    def _serve_snapshot(self):
        """Serve single JPEG snapshot"""
        with self.frame_lock:
            frame_data = self.frame_buffer
        
        if frame_data is None:
            frame_data = self._create_placeholder_frame()
        
        self.send_response(200)
        self.send_header('Content-Type', 'image/jpeg')
        self.send_header('Content-Length', len(frame_data))
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        self.wfile.write(frame_data)
    
    def _serve_status(self):
        """Serve status page"""
        status = "<html><body><h1>MJPEG Camera Streamer</h1>"
        status += "<p>Endpoints:</p><ul>"
        status += "<li><a href='/camera'>/camera</a> - MJPEG stream (for Godot)</li>"
        status += "<li><a href='/snapshot'>/snapshot</a> - Single JPEG image</li>"
        status += "</ul></body></html>"
        
        self.send_response(200)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        self.wfile.write(status.encode())
    
    @classmethod
    def _create_placeholder_frame(cls):
        """Create a placeholder frame when no camera data available"""
        img = np.zeros((480, 640, 3), dtype=np.uint8)
        cv2.putText(img, "No Camera Feed", (180, 240), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
        _, jpeg = cv2.imencode('.jpg', img, [int(cv2.IMWRITE_JPEG_QUALITY), cls.jpeg_quality])
        return jpeg.tobytes()


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Threaded HTTP server for handling multiple connections"""
    daemon_threads = True
    allow_reuse_address = True


class MJPEGStreamer:
    """
    MJPEG streaming server for camera feed.
    
    Serves camera frames via HTTP as MJPEG stream that can be consumed by:
    - Godot game engine (HTTPClient)
    - Web browsers (img tag or video element)
    - Any MJPEG-compatible client
    
    Usage:
        streamer = MJPEGStreamer(port=4243)
        streamer.start()
        
        # In camera loop:
        streamer.update_frame(frame)
        
        streamer.stop()
    """
    
    DEFAULT_PREVIEW_FPS = 30.0
    
    def __init__(self, port: int = 4243, quality: int = 70, preview_fps: float = DEFAULT_PREVIEW_FPS):
        """
        Initialize MJPEG streamer.
        
        Args:
            port: HTTP server port (default: 4243)
            quality: JPEG quality 0-100 (default: 70, good balance)
            preview_fps: Maximum MJPEG preview send rate (default: 30 FPS)
        """
        self.port = port
        self.quality = quality
        self.preview_fps = max(float(preview_fps), 0.0)
        self._preview_interval = (1.0 / self.preview_fps) if self.preview_fps > 0 else 0.0
        self._server = None
        self._server_thread = None
        self._running = False
        self._frame = None
        self._last_publish_time = None
        self._lock = threading.Lock()
        self._frame_ready = threading.Condition(self._lock)
        
        # Update handler class variables
        MJPEGHTTPHandler.jpeg_quality = quality
        MJPEGHTTPHandler.frame_buffer = None
        MJPEGHTTPHandler.frame_sequence = 0
        MJPEGHTTPHandler.frame_lock = self._lock
        MJPEGHTTPHandler.frame_ready = self._frame_ready
    
    def start(self) -> bool:
        """
        Start the HTTP server in a background thread.
        
        Returns:
            True if server started successfully
        """
        if self._running:
            return True
        
        try:
            self._server = ThreadedHTTPServer(('0.0.0.0', self.port), MJPEGHTTPHandler)
            self._server_thread = threading.Thread(target=self._server.serve_forever, daemon=True)
            self._server_thread.start()
            self._running = True
            print(f"[MJPEG] Streamer started on http://0.0.0.0:{self.port}/camera")
            return True
        except Exception as e:
            print(f"[MJPEG] Failed to start server: {e}")
            return False
    
    def stop(self):
        """Stop the HTTP server"""
        if not self._running:
            return
        
        self._running = False
        if self._server:
            self._server.shutdown()
            self._server.server_close()
        
        print("[MJPEG] Streamer stopped")
    
    def update_frame(self, frame):
        """
        Update the current frame to be streamed.
        
        Call this with each new camera frame. The frame will be
        encoded as JPEG and made available to all connected clients.
        The preview stream publishes at most `preview_fps` frames per
        second and only wakes clients when a newly encoded frame arrives.
        
        Args:
            frame: OpenCV BGR image (numpy array)
        """
        if frame is None:
            return
        
        try:
            now = time.monotonic()
            if self._preview_interval > 0 and self._last_publish_time is not None:
                if (now - self._last_publish_time) < self._preview_interval:
                    return
            
            # Encode frame as JPEG
            encode_params = [int(cv2.IMWRITE_JPEG_QUALITY), self.quality]
            success, jpeg_buffer = cv2.imencode('.jpg', frame, encode_params)
            if not success:
                return
            
            with self._frame_ready:
                MJPEGHTTPHandler.frame_buffer = jpeg_buffer.tobytes()
                MJPEGHTTPHandler.frame_sequence += 1
                self._last_publish_time = now
                self._frame_ready.notify_all()
                
        except Exception as e:
            print(f"[MJPEG] Frame encoding error: {e}")
    
    def is_running(self) -> bool:
        """Check if streamer is running"""
        return self._running
    
    def get_url(self) -> str:
        """Get the stream URL"""
        return f"http://127.0.0.1:{self.port}/camera"


# Test/standalone mode
if __name__ == "__main__":
    import time
    
    print("MJPEG Streamer Test Mode")
    print("========================")
    
    # Create streamer
    streamer = MJPEGStreamer(port=4243, quality=70)
    
    if not streamer.start():
        print("Failed to start streamer")
        exit(1)
    
    print(f"\nStream available at: {streamer.get_url()}")
    print("Open in browser or VLC to test")
    print("Press Ctrl+C to stop\n")
    
    # Create test pattern
    try:
        frame_count = 0
        while True:
            # Generate moving test pattern
            img = np.zeros((480, 640, 3), dtype=np.uint8)
            
            # Moving circle
            x = int(320 + 200 * np.sin(frame_count * 0.05))
            y = int(240 + 150 * np.cos(frame_count * 0.03))
            cv2.circle(img, (x, y), 50, (0, 255, 0), -1)
            
            # Frame counter
            cv2.putText(img, f"Frame: {frame_count}", (20, 40), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
            cv2.putText(img, f"Quality: {streamer.quality}%", (20, 80), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
            
            # Update streamer
            streamer.update_frame(img)
            
            frame_count += 1
            time.sleep(0.033)  # ~30 FPS
            
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        streamer.stop()
        print("Done")
