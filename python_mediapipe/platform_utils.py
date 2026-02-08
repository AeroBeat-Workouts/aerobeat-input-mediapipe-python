"""Platform-specific optimizations for AeroBeat MediaPipe input"""

import platform
import os


def set_windows_priority():
    """Set process to HIGH_PRIORITY_CLASS on Windows for real-time performance"""
    if platform.system() != "Windows":
        return False
    
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetCurrentProcess()
        # HIGH_PRIORITY_CLASS = 0x00000080
        # REALTIME_PRIORITY_CLASS = 0x00000100 (use with caution)
        result = kernel32.SetPriorityClass(handle, 0x00000080)
        if result:
            print("✓ Windows process priority set to HIGH")
            return True
        else:
            print("⚠ Failed to set Windows process priority")
            return False
    except Exception as e:
        print(f"⚠ Could not set Windows priority: {e}")
        return False


def set_cpu_affinity(cores=None):
    """Pin process to specific CPU cores (Windows only)"""
    if platform.system() != "Windows":
        return False
    
    try:
        import psutil
        p = psutil.Process()
        if cores is None:
            # Use all available cores by default
            cores = list(range(psutil.cpu_count()))
        p.cpu_affinity(cores)
        print(f"✓ CPU affinity set to cores: {cores}")
        return True
    except Exception as e:
        print(f"⚠ Could not set CPU affinity: {e}")
        return False


def check_windows_defender():
    """Warn if Windows Defender might interfere with performance"""
    if platform.system() != "Windows":
        return
    
    print("💡 Tip: Add AeroBeat folder to Windows Defender exclusions")
    print("   for best performance (Settings → Privacy → Virus protection)")


def disable_app_nap():
    """Disable App Nap on macOS for real-time performance"""
    if platform.system() != "Darwin":
        return False
    
    try:
        import ctypes
        from ctypes import cdll, c_void_p, c_bool
        
        objc = cdll.LoadLibrary("/usr/lib/libobjc.dylib")
        foundation = cdll.LoadLibrary("/System/Library/Frameworks/Foundation.framework/Foundation")
        
        # Get NSProcessInfo class
        NSProcessInfo = objc.objc_getClass(b"NSProcessInfo")
        # Get processInfo method
        processInfo = objc.sel_registerName(b"processInfo")
        # Call [NSProcessInfo processInfo]
        info = objc.objc_msgSend(NSProcessInfo, processInfo)
        
        # Disable automatic termination
        disable = objc.sel_registerName(b"disableAutomaticTermination:")
        objc.objc_msgSend(info, disable, b"AeroBeat")
        
        print("✓ App Nap disabled")
        return True
    except Exception as e:
        print(f"⚠ Could not disable App Nap: {e}")
        return False


def prevent_sleep():
    """Prevent system sleep during gameplay (macOS only)"""
    if platform.system() != "Darwin":
        return False
    
    try:
        import subprocess
        # Use caffeinate to prevent sleep
        # -d: prevent display sleep
        # -i: prevent idle sleep
        # -s: prevent system sleep
        # -u: declare user activity
        # -w: wait for process to exit
        subprocess.Popen(
            ["caffeinate", "-disu", "-w", str(os.getpid())],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        print("✓ System sleep disabled (caffeinate active)")
        return True
    except Exception as e:
        print(f"⚠ Could not prevent sleep: {e}")
        return False


def check_macos_camera_permissions():
    """Remind about camera permissions on macOS"""
    if platform.system() != "Darwin":
        return
    
    print("📷 macOS: Grant camera permission in")
    print("   System Settings → Privacy & Security → Camera")


def setup_platform_optimizations():
    """Setup all platform-specific optimizations based on OS"""
    current_platform = platform.system()
    
    print(f"🔧 Platform: {current_platform}")
    
    if current_platform == "Windows":
        set_windows_priority()
        # Optional: set_cpu_affinity([0, 1])  # Pin to first 2 cores
        check_windows_defender()
    elif current_platform == "Darwin":
        disable_app_nap()
        prevent_sleep()
        check_macos_camera_permissions()
    else:
        print(f"✓ Linux/Other: No platform-specific optimizations needed")
    
    return current_platform
