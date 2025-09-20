extends Node

# メインスレッド版SyncLoggerのデモ
# スレッドを使わずに直接ログ送信をテスト

var simple_logger: MainThreadSimpleLogger

func _ready():
	print("=== MainThread Simple Logger Demo Started ===")
	
	# シンプルロガーをセットアップ
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9999)  # 標準ポート使用
	print("MainThread Simple Logger setup completed")
	
	# 各レベルのログを送信
	print("Sending test logs...")
	var result1 = simple_logger.debug("This is a debug message from mainthread")
	var result2 = simple_logger.info("Application started successfully (mainthread)")
	var result3 = simple_logger.warning("This is a warning message (mainthread)")
	var result4 = simple_logger.error("This is an error message (mainthread)")
	
	print("Log sending results: ", result1, ", ", result2, ", ", result3, ", ", result4)
	
	# カテゴリ付きログ
	simple_logger.log("Player spawned at position (100, 200)", "gameplay")
	simple_logger.log("Level loaded: Forest (mainthread version)", "level")
	simple_logger.log("Network connection established (mainthread)", "network")
	
	print("Demo logs sent! Check the log_receiver.py output on port 9996")
	
	# 3秒後に終了（スレッド問題回避のため短時間）
	await get_tree().create_timer(3.0).timeout
	
	print("=== MainThread Simple Logger Demo Finished ===")
	
	# プログラム終了
	get_tree().quit()
