"""Platform-specific utilities for AeroBeat MediaPipe

Handles Windows, macOS, and Linux optimizations automatically.
"""

import platform
import os
import sys


def setup_platform_optimizations():
    """Apply platform-specific optimizations. Call at startup."""
    system = platform.system()
    
    if system == "Windows":
        _setup_windows()
    elif system == "Darwin":
        _setup_macos()
    else:
        print(f"✓ Linux detected - no special optimizations needed")


def _setup_windows():
    """Windows-specific optimizations"""
    print("🔧 Applying Windows optimizations...")
    
    try:
        import ctypes
        
        # Set high process priority
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetCurrentProcess()
        
        # HIGH_PRIORITY_CLASS = 0x00000080
        # ABOVE_NORMAL_PRIORITY_CLASS = 0x00008000 (safer alternative)
        result = kernel32.SetPriorityClass(handle, 0x00008000)
        
        if result:
            print("  ✓ Process priority set to ABOVE_NORMAL")
        else:
            print("  ⚠ Could not set process priority (may need admin rights)")
            
    except Exception as e:
        print(f"  ⚠ Windows optimization error: {e}")
    
    # Tips for users
    print("\n💡 Windows Performance Tips:")
    print("   • Add AeroBeat folder to Windows Defender exclusions")
    print("   • Set power plan to 'High Performance'")
    print("   • Enable Game Mode in Settings → Gaming")


def _setup_macos():
    """macOS-specific optimizations"""
    print("🔧 Applying macOS optimizations...")
    
    # Disable App Nap
    try:
        import subprocess
        # Use caffeinate to prevent App Nap and sleep
        # -d: prevent display from sleeping
        # -i: prevent system from idle sleeping  
        # -s: prevent system from sleeping
        # -u: declare user activity
        # -w: wait for process to exit
        subprocess.Popen(
            ["caffeinate", "-disu", "-w", str(os.getpid())],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        print("  ✓ App Nap disabled (caffeinate active)")
    except Exception as e:
        print(f"  ⚠ Could not disable App Nap: {e}")
    
    # Camera permissions reminder
    print("\n📷 macOS Camera Permission:")
    print("   Grant camera access in:")
    print("   System Settings → Privacy & Security → Camera")
    
    # Architecture info
    import platform
    arch = platform.machine()
    if 'arm' in arch.lower():
        print(f"\n🍎 Apple Silicon detected ({arch})")
        print("   Unified memory architecture active")
    else:
        print(f"\n💻 Intel Mac detected ({arch})")


def get_platform_info():
    """Get platform information for debugging"""
    return {
        'system': platform.system(),
        'release': platform.release(),
        'version': platform.version(),
        'machine': platform.machine(),
        'processor': platform.processor()
    }
