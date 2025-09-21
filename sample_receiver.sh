#!/bin/bash
# SyncLogger Receiver - Unix Sample (not maintained)
# Feel free to customize for your needs

# Check Python availability
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Error: Python not found"
    exit 1
fi

echo "Starting SyncLogger receiver..."
$PYTHON_CMD sample_receiver.py --timestamp --save logs.txt