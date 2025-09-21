extends Node

func _ready():
	print("=== SyncLogger レシーバーテスト ===")

	# SyncLogger確認（AutoLoadとして）
	var sync_logger = get_node_or_null("/root/SyncLogger")
	if sync_logger:
		print("SyncLogger found as AutoLoad")

		# 基本設定
		sync_logger.setup("127.0.0.1", 9999)
		print("Setup completed: ", sync_logger.get_host(), ":", sync_logger.get_port())

		# テストメッセージ送信
		sync_logger.info("テストメッセージ1: 基本ログ")
		sync_logger.warning("テストメッセージ2: 警告ログ")
		sync_logger.error("テストメッセージ3: エラーログ")
		sync_logger.debug("テストメッセージ4: デバッグログ")
		sync_logger.critical("テストメッセージ5: 重要ログ")

		print("5個のテストメッセージを送信しました")

		# 少し待ってから終了
		await get_tree().create_timer(1.0).timeout
		print("テスト完了")
	else:
		print("ERROR: SyncLogger not found as AutoLoad")

	get_tree().quit()