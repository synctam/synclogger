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
