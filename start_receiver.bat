@echo off
REM SyncLogger Log Receiver - Windows Batch Script
REM 使用方法: start_receiver.bat

echo ========================================
echo  SyncLogger UDP Log Receiver (Windows)
echo ========================================
echo.

REM Pythonの存在確認
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python 3.6+ from https://python.org
    pause
    exit /b 1
)

echo 🐍 Python detected
echo 🚀 Starting log receiver on 127.0.0.1:9999...
echo 📡 Press Ctrl+C to stop
echo.

REM ログレシーバー起動（タイムスタンプ表示、ログファイル保存）
python log_receiver.py --timestamp --save synclogger_output.txt

echo.
echo 👋 Log receiver stopped.
pause