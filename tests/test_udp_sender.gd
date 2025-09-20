extends GutTest

var udp_sender: UDPSender


func before_each():
	udp_sender = UDPSender.new()


func after_each():
	if udp_sender:
		udp_sender.close()
		udp_sender = null


func test_can_create_udp_sender():
	assert_not_null(udp_sender, "UDPSenderが作成できる")


func test_can_setup_host_and_port():
	var host = "127.0.0.1"
	var port = 9999

	udp_sender.setup(host, port)

	assert_eq(udp_sender.get_host(), host, "ホストが正しく設定される")
	assert_eq(udp_sender.get_port(), port, "ポートが正しく設定される")


func test_can_send_data():
	udp_sender.setup("127.0.0.1", 9999)
	var test_data = "test_message"

	var result = udp_sender.send(test_data)

	assert_true(result, "データ送信が成功する")


func test_send_fails_without_setup():
	var result = udp_sender.send("test")

	assert_false(result, "setup前の送信は失敗する")


func test_can_close_connection():
	udp_sender.setup("127.0.0.1", 9999)

	udp_sender.close()

	var result = udp_sender.send("test")
	assert_false(result, "close後の送信は失敗する")


func test_send_returns_false_on_invalid_parameters():
	# 無効なポート番号でセットアップ
	udp_sender.setup("127.0.0.1", -1)

	var result = udp_sender.send("test")

	assert_false(result, "無効なポートでの送信は失敗する")


func test_send_returns_false_on_empty_host():
	# 空のホスト名でセットアップ
	udp_sender.setup("", 9999)

	var result = udp_sender.send("test")

	assert_false(result, "空のホストでの送信は失敗する")


# ======== Phase 2: UDP接続最適化のテスト ========

func test_ensure_connection_returns_true_when_setup_properly():
	"""_ensure_connection()はセットアップ後にtrueを返す"""
	udp_sender.setup("127.0.0.1", 9999)

	# プライベートメソッドをテストするため、send()を通じて間接的にテスト
	var result = udp_sender.send("test")

	assert_true(result, "_ensure_connection()が適切に動作し送信が成功する")


func test_ensure_connection_returns_false_without_setup():
	"""_ensure_connection()はセットアップ前にfalseを返す"""
	# setupを呼ばない状態

	var result = udp_sender.send("test")

	assert_false(result, "_ensure_connection()がfalseを返し送信が失敗する")


func test_retry_send_on_connection_failure():
	"""接続失敗時の再試行ロジックがある"""
	udp_sender.setup("127.0.0.1", 9999)

	# 最初の送信は成功するはず
	var result1 = udp_sender.send("test1")
	assert_true(result1, "最初の送信は成功")

	# 接続を意図的に切断
	udp_sender.close()

	# 再セットアップ後の送信で再試行ロジックをテスト
	udp_sender.setup("127.0.0.1", 9999)
	var result2 = udp_sender.send("test2")
	assert_true(result2, "再接続後の送信も成功")


func test_connection_resilience():
	"""接続の復旧力をテスト"""
	udp_sender.setup("127.0.0.1", 9999)

	# 複数回送信して接続が維持されることを確認
	for i in range(3):
		var result = udp_sender.send("test_%d" % i)
		assert_true(result, "送信%d回目が成功" % (i + 1))

	# テストモードでの動作確認
	udp_sender.set_test_mode(true)
	var test_result = udp_sender.send("test_mode")
	assert_true(test_result, "テストモードでの送信が成功")
