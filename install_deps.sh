#!/bin/bash
# Install Python dependencies for AeroBeat MediaPipe addon
# This script creates a virtual environment and installs required packages

set -euo pipefail  # Exit on error, undefined vars, pipe failures

echo "Installing AeroBeat MediaPipe dependencies..."

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 not found. Please install Python 3.8 or later."
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo "✓ Found Python $PYTHON_VERSION"

# Remove broken venv if it exists
if [ -d "venv" ]; then
    echo "→ Removing existing virtual environment..."
    rm -rf venv
fi

# Create virtual environment
echo "→ Creating virtual environment..."
if ! python3 -m venv venv; then
    echo "❌ Error: Failed to create virtual environment"
    echo "   Try: python3 -m venv venv --without-pip && source venv/bin/activate && curl https://bootstrap.pypa.io/get-pip.py | python"
    exit 1
fi

# Verify venv was created correctly
if [ ! -f "venv/bin/activate" ]; then
    echo "❌ Error: Virtual environment created but activate script is missing"
    exit 1
fi

if [ ! -f "venv/bin/pip" ]; then
    echo "❌ Error: pip not found in virtual environment"
    exit 1
fi

echo "✓ Virtual environment created successfully"

# Activate virtual environment
echo "→ Activating virtual environment..."
source venv/bin/activate

# Verify pip works
if ! pip --version &> /dev/null; then
    echo "❌ Error: pip is not working in virtual environment"
    exit 1
fi

echo "✓ pip is available: $(pip --version)"

# Install dependencies
echo "→ Installing packages..."
if ! pip install -r requirements.txt; then
    echo "❌ Error: Failed to install packages from requirements.txt"
    exit 1
fi

# Verify MediaPipe is importable
echo "→ Verifying MediaPipe installation..."
if ! venv/bin/python -c "import mediapipe; print(f'MediaPipe version: {mediapipe.__version__}')" 2>/dev/null; then
    echo "❌ Error: MediaPipe installation verification failed"
    exit 1
fi

echo ""
echo "✅ Installation complete!"
echo "   MediaPipe is ready to use."
echo ""
echo "To activate manually: source venv/bin/activate"
