extends Node

## SyncLogger公式デモシーン
## 
## このシーンはSyncLoggerアドオンの基本的な使用方法をデモンストレーションします。
## スレッドベースのリアルタイムUDPログ送信機能を実際に体験できます。
##
## 使用方法:
## 1. log_receiver.pyを別ターミナルで起動
## 2. このシーンを実行
## 3. ログがリアルタイムで受信されることを確認

func _ready():
	print("=== SyncLogger Demo Started ===")
	
	# SyncLoggerセットアップ
	# ホストとポートを指定してログ送信先を設定
	SyncLogger.setup("127.0.0.1", 9998)
	print("SyncLogger setup completed")
	
	# 各レベルのログを送信
	# 異なるログレベルでのログ送信例
	SyncLogger.debug("This is a debug message")
	SyncLogger.info("Application started successfully")
	SyncLogger.warning("This is a warning message")
	SyncLogger.error("This is an error message")
	
	# カテゴリ付きログ
	# ログにカテゴリを追加してシステム別分類
	SyncLogger.log("Player spawned at position (100, 200)", "gameplay")
	SyncLogger.log("Level loaded: Forest", "level")
	SyncLogger.log("Network connection established", "network")
	
	print("Demo logs sent!")
	print("Check the log_receiver.py output on port 9998")
	
	# 5秒後にシャットダウン
	await get_tree().create_timer(5.0).timeout
	
	await SyncLogger.shutdown()
	print("=== SyncLogger Demo Finished ===")
	
	# プログラム終了
	get_tree().quit()