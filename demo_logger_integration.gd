extends Node

# Logger Interceptor統合デモ
# 実際のシステムログキャプチャをテスト

func _ready():
	print("=== Logger Interceptor統合デモ開始 ===")

	# SyncLogger設定
	SyncLogger.setup("127.0.0.1", 9999)
	print("SyncLogger設定完了: ", SyncLogger.get_host(), ":", SyncLogger.get_port())

	# システムログキャプチャ状態確認
	print("システムキャプチャ有効:", SyncLogger.is_system_capture_enabled())
	print("エラーキャプチャ有効:", SyncLogger.is_capture_errors_enabled())
	print("メッセージキャプチャ有効:", SyncLogger.is_capture_messages_enabled())

	# 待機してからテスト実行
	await get_tree().create_timer(1.0).timeout
	test_logger_integration()

func test_logger_integration():
	print("\n=== ログテスト開始 ===")

	# 1. 従来のSyncLoggerAPI（アプリケーションログ）
	print("1. アプリケーションログテスト")
	SyncLogger.info("アプリケーション情報ログ")
	SyncLogger.warning("アプリケーション警告ログ")
	SyncLogger.error("アプリケーションエラーログ")

	await get_tree().create_timer(0.5).timeout

	# 2. システムログ（print関数）- 自動キャプチャ
	print("2. システムメッセージテスト（自動キャプチャ）")
	print("これはprint()で出力されたメッセージです")
	print("自動的にUDP送信されるはずです")

	await get_tree().create_timer(0.5).timeout

	# 3. エラー生成テスト（自動キャプチャ）
	print("3. システムエラーテスト（自動キャプチャ）")
	test_system_errors()

	await get_tree().create_timer(0.5).timeout

	# 4. 統計情報表示
	print("4. 統計情報")
	var stats = SyncLogger.get_system_log_stats()
	print("統計:", stats)

	await get_tree().create_timer(0.5).timeout

	# 5. キャプチャ制御テスト
	print("5. キャプチャ制御テスト")
	test_capture_control()

func test_system_errors():
	# 意図的にエラーを発生させてキャプチャテスト
	push_warning("テスト警告: これは意図的な警告です")

	# 存在しないノードアクセス（エラー生成）
	# Note: このエラーはtry-catchできないため、実際のログに出力される
	var nonexistent = get_node_or_null("NonExistentNode")
	if not nonexistent:
		print("存在しないノードアクセステスト完了（エラーなし）")

func test_capture_control():
	print("キャプチャ制御前 - メッセージ有効:", SyncLogger.is_capture_messages_enabled())

	# メッセージキャプチャを無効化
	SyncLogger.set_capture_messages(false)
	print("メッセージキャプチャを無効化しました")
	print("この print() は UDP送信されないはずです")

	await get_tree().create_timer(0.5).timeout

	# メッセージキャプチャを再有効化
	SyncLogger.set_capture_messages(true)
	print("メッセージキャプチャを再有効化しました")
	print("この print() は再びUDP送信されるはずです")

	await get_tree().create_timer(1.0).timeout

	print("\n=== デモ完了 ===")
	print("Python受信スクリプト (python log_receiver.py) で")
	print("アプリケーションログとシステムログの両方が")
	print("受信できていることを確認してください。")

	# 自動終了
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
