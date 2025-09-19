#!/usr/bin/env python3
"""
SyncLogger UDP Log Receiver

Godot SyncLoggerから送信されるUDPログを受信・表示します。

使用方法:
    python log_receiver.py [host] [port]

例:
    python log_receiver.py                    # localhost:9999 で受信
    python log_receiver.py 127.0.0.1 8888   # 127.0.0.1:8888 で受信
"""

import socket
import json
import sys
from datetime import datetime


def start_log_receiver(host='localhost', port=9999):
    """UDPログレシーバーを開始する"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.bind((host, port))
        print(f"SyncLogger Receiver started on {host}:{port}")
        print("Waiting for logs from Godot SyncLogger...")
        print("Press Ctrl+C to stop")
        print("-" * 50)
        
        while True:
            try:
                data, addr = sock.recvfrom(1024)
                log_data = json.loads(data.decode('utf-8'))
                
                # ログデータから情報を抽出
                timestamp = log_data.get('timestamp', 0)
                frame = log_data.get('frame', '?')
                physics_frame = log_data.get('physics_frame', '?')
                level = log_data.get('level', 'info').upper()
                category = log_data.get('category', 'general')
                message = log_data.get('message', '')
                
                # タイムスタンプをフォーマット（マイクロ秒まで）
                ts = datetime.fromtimestamp(timestamp)
                time_str = ts.strftime('%H:%M:%S.%f')  # マイクロ秒まで
                
                # ログレベルに応じた色付け（ANSI escape codes）
                level_colors = {
                    'DEBUG': '\033[36m',    # Cyan
                    'INFO': '\033[32m',     # Green
                    'WARNING': '\033[33m',  # Yellow
                    'ERROR': '\033[31m',    # Red
                    'CRITICAL': '\033[35m'  # Magenta
                }
                color = level_colors.get(level, '\033[37m')  # Default: White
                reset = '\033[0m'
                
                # ログを表示
                print(f"[{time_str}] {color}{level:8}{reset} "
                      f"F:{frame:>6} PF:{physics_frame:>6} "
                      f"[{category}] {message}")
                
            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
                print(f"Raw data: {data}")
            except UnicodeDecodeError as e:
                print(f"Unicode decode error: {e}")
            except Exception as e:
                print(f"Error processing log: {e}")
                
    except KeyboardInterrupt:
        print("\n" + "-" * 50)
        print("SyncLogger Receiver stopped")
    except OSError as e:
        print(f"Socket error: {e}")
        print(f"Make sure port {port} is not already in use")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        try:
            sock.close()
        except:
            pass


def main():
    """メイン関数"""
    host = 'localhost'
    port = 9999
    
    # コマンドライン引数の処理
    if len(sys.argv) >= 2:
        host = sys.argv[1]
    if len(sys.argv) >= 3:
        try:
            port = int(sys.argv[2])
        except ValueError:
            print(f"Invalid port number: {sys.argv[2]}")
            sys.exit(1)
    
    start_log_receiver(host, port)


if __name__ == "__main__":
    main()