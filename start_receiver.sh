#!/bin/bash
# SyncLogger Log Receiver - Unix Shell Script
# 使用方法: ./start_receiver.sh

echo "========================================"
echo " SyncLogger UDP Log Receiver (Unix)"
echo "========================================"
echo

# Pythonの存在確認
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "❌ Python is not installed or not in PATH"
        echo "Please install Python 3.6+ from your package manager"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

echo "🐍 Python detected: $($PYTHON_CMD --version)"
echo "🚀 Starting log receiver on 127.0.0.1:9999..."
echo "📡 Press Ctrl+C to stop"
echo

# 実行権限を設定
chmod +x log_receiver.py

# ログレシーバー起動（タイムスタンプ表示、ログファイル保存）
$PYTHON_CMD log_receiver.py --timestamp --save synclogger_output.txt

echo
echo "👋 Log receiver stopped."