#!/usr/bin/env python3
"""
SyncLogger UDP Log Receiver
Godot SyncLogger用の高機能ログレシーバー

使用方法:
    python log_receiver.py --port 9999 --host 127.0.0.1
    python log_receiver.py --save logs.txt --timestamp
"""

import socket
import json
import argparse
import sys
from datetime import datetime
import signal
import os

class LogReceiver:
    def __init__(self, host="127.0.0.1", port=9999, save_file=None, show_timestamp=False):
        self.host = host
        self.port = port
        self.save_file = save_file
        self.show_timestamp = show_timestamp
        self.socket = None
        self.file_handle = None
        self.running = False

        # ログレベル別の色分け（ANSIカラーコード）
        self.colors = {
            "trace": "\033[90m",    # 灰色
            "debug": "\033[36m",    # シアン
            "info": "\033[32m",     # 緑
            "warning": "\033[33m",  # 黄
            "error": "\033[31m",    # 赤
            "critical": "\033[91m", # 明るい赤
            "reset": "\033[0m"      # リセット
        }

    def setup(self):
        """UDPソケットとファイルハンドルの初期化"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.socket.bind((self.host, self.port))

            if self.save_file:
                self.file_handle = open(self.save_file, 'a', encoding='utf-8')

            print(f"🚀 SyncLogger Receiver started on {self.host}:{self.port}")
            if self.save_file:
                print(f"📁 Logs will be saved to: {self.save_file}")
            print("📡 Waiting for logs... (Ctrl+C to stop)")
            print("-" * 50)

            return True
        except Exception as e:
            print(f"❌ Setup failed: {e}")
            return False

    def format_log_entry(self, log_data):
        """ログエントリの整形"""
        try:
            # JSONパース
            if isinstance(log_data, str):
                data = json.loads(log_data)
            else:
                data = log_data

            # 基本情報取得
            level = data.get('level', 'info').upper()
            message = data.get('message', '')
            category = data.get('category', 'general')

            # フレーム情報（オプション）
            frame = data.get('frame', '')
            physics_frame = data.get('physics_frame', '')

            # タイムスタンプ処理
            timestamp = data.get('timestamp', '')
            if timestamp and self.show_timestamp:
                if isinstance(timestamp, (int, float)):
                    dt = datetime.fromtimestamp(timestamp)
                    time_str = dt.strftime('%H:%M:%S.%f')[:-3]  # ミリ秒まで
                else:
                    time_str = str(timestamp)
                time_prefix = f"[{time_str}] "
            else:
                time_prefix = ""

            # カラー適用
            color = self.colors.get(level.lower(), "")
            reset = self.colors["reset"]

            # フレーム情報の表示
            frame_info = ""
            if frame or physics_frame:
                frame_info = f" (F:{frame}/P:{physics_frame})"

            # 整形された出力
            formatted = f"{time_prefix}{color}[{level:8}]{reset} [{category}]{frame_info} {message}"

            return formatted

        except json.JSONDecodeError:
            # JSONでない場合はそのまま表示
            return f"[RAW] {log_data}"
        except Exception as e:
            return f"[PARSE_ERROR] {log_data} (Error: {e})"

    def save_to_file(self, formatted_log):
        """ファイル保存（ANSIカラーコードを除去）"""
        if self.file_handle:
            # ANSIカラーコードを除去
            clean_log = self._remove_ansi_codes(formatted_log)
            self.file_handle.write(clean_log + "\n")
            self.file_handle.flush()

    def _remove_ansi_codes(self, text):
        """ANSIカラーコードを除去"""
        import re
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', text)

    def start(self):
        """ログ受信開始"""
        if not self.setup():
            return False

        self.running = True
        log_count = 0

        try:
            while self.running:
                try:
                    # UDP受信（タイムアウト設定）
                    self.socket.settimeout(1.0)
                    data, addr = self.socket.recvfrom(4096)

                    # ログ処理
                    log_text = data.decode('utf-8')
                    formatted_log = self.format_log_entry(log_text)

                    # コンソール出力
                    print(formatted_log)

                    # ファイル保存
                    self.save_to_file(formatted_log)

                    log_count += 1

                except socket.timeout:
                    # タイムアウト（正常）
                    continue
                except KeyboardInterrupt:
                    # Ctrl+C
                    break
                except Exception as e:
                    print(f"⚠️  Log processing error: {e}")

        except KeyboardInterrupt:
            pass
        finally:
            self.cleanup()
            print(f"\n📊 Received {log_count} logs. Goodbye!")

    def cleanup(self):
        """リソースクリーンアップ"""
        self.running = False
        if self.socket:
            self.socket.close()
        if self.file_handle:
            self.file_handle.close()

def signal_handler(sig, frame):
    """シグナルハンドラー"""
    print("\n🛑 Stopping receiver...")
    sys.exit(0)

def main():
    parser = argparse.ArgumentParser(description='SyncLogger UDP Log Receiver')
    parser.add_argument('--host', default='127.0.0.1', help='Listen host (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=9999, help='Listen port (default: 9999)')
    parser.add_argument('--save', help='Save logs to file')
    parser.add_argument('--timestamp', action='store_true', help='Show timestamps')
    parser.add_argument('--no-color', action='store_true', help='Disable color output')

    args = parser.parse_args()

    # シグナルハンドラー設定
    signal.signal(signal.SIGINT, signal_handler)

    # レシーバー初期化
    receiver = LogReceiver(
        host=args.host,
        port=args.port,
        save_file=args.save,
        show_timestamp=args.timestamp
    )

    # カラー無効化
    if args.no_color:
        receiver.colors = {k: "" for k in receiver.colors}

    # 開始
    receiver.start()

if __name__ == "__main__":
    main()