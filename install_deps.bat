@echo off
echo Installing AeroBeat MediaPipe dependencies...

python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found. Please install Python 3.8 or later.
    exit /b 1
)

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing packages...
venv\Scripts\pip install -r requirements.txt

echo Installation complete!
echo To activate in future: venv\Scripts\activate