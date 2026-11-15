# @title Computer Info
# @category Tools
# @kind Console program
# @where Save as sysinfo.py and run: python3 sysinfo.py
# @keywords python system info, python platform module, python disk usage, python cpu count
# @about Shows facts about your computer: operating system, Python version, CPU cores and free disk space.

import os
import platform
import shutil
import sys
from datetime import datetime

print("=== Your Computer ===")
print("Operating system:", platform.system(), platform.release())
print("Computer name:", platform.node())
print("Processor type:", platform.machine())
print("CPU cores:", os.cpu_count())
print("Python version:", sys.version.split()[0])
print("Python is at:", sys.executable)
print("Current folder:", os.getcwd())
print("Date and time:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

disk = shutil.disk_usage(os.path.abspath(os.sep))
gb = 1024 ** 3
used_percent = disk.used / disk.total * 100
bar = "#" * int(used_percent // 5) + "-" * (20 - int(used_percent // 5))
print(f"Disk: {disk.used / gb:.0f} GB used of {disk.total / gb:.0f} GB  [{bar}] {used_percent:.0f}%")
print(f"Free space: {disk.free / gb:.1f} GB")
