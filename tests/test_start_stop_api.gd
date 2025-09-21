extends GutTest

var _logger: SyncLogger
var _mock_sender: Node

func before_each():
	_logger = preload("res://addons/synclogger/synclogger.gd").new()
	_mock_sender = Node.new()
	add_child_autofree(_logger)
	add_child_autofree(_mock_sender)


func after_each():
	if _logger:
		_logger.stop()


# Test: デフォルト値での初期化
func test_default_values():
	assert_eq(_logger._host, "127.0.0.1", "デフォルトホストは127.0.0.1")
	assert_eq(_logger._port, 9999, "デフォルトポートは9999")
	assert_false(_logger._is_running, "初期状態は停止中")


# Test: setup()で設定のみ更新（接続なし）
func test_setup_only_updates_settings():
	_logger.setup("192.168.1.100", 8888)

	assert_eq(_logger._host, "192.168.1.100", "ホストが更新される")
	assert_eq(_logger._port, 8888, "ポートが更新される")
	assert_false(_logger._is_running, "setupでは開始されない")
	assert_null(_logger._udp_sender, "setupではUDP接続されない")


# Test: start()でUDP接続とログ開始
func test_start_connects_and_enables_logging():
	_logger.start()

	assert_true(_logger._is_running, "startで実行状態になる")
	assert_not_null(_logger._udp_sender, "startでUDPSenderが作成される")


# Test: stop()でUDP切断とログ停止
func test_stop_disconnects_and_disables_logging():
	_logger.start()
	_logger.stop()

	assert_false(_logger._is_running, "stopで停止状態になる")
	assert_null(_logger._udp_sender, "stopでUDPSenderが解放される")


# Test: restart()はstop→startの便利メソッド
func test_restart_stops_and_starts():
	_logger.setup("10.0.0.1", 7777)
	_logger.start()
	var old_sender = _logger._udp_sender

	_logger.restart()

	assert_true(_logger._is_running, "restartで再び実行状態")
	assert_not_null(_logger._udp_sender, "新しいUDPSenderが作成される")
	# 新しいインスタンスが作成されることを確認
	assert_ne(_logger._udp_sender, old_sender, "異なるUDPSenderインスタンス")


# Test: 実行中でない時はログが送信されない
func test_logging_disabled_when_not_running():
	# 開始前
	var result = _logger.info("test message")
	assert_false(result, "停止中はログ送信されない")

	# 開始後
	_logger.start()
	result = _logger.info("test message")
	assert_true(result, "実行中はログ送信される")

	# 停止後
	_logger.stop()
	result = _logger.info("test message")
	assert_false(result, "停止後はログ送信されない")


# Test: start()を連続で呼んでも安全
func test_multiple_starts_are_safe():
	_logger.start()
	var first_sender = _logger._udp_sender

	# 2回目のstart（警告は出るが安全）
	_logger.start()

	assert_true(_logger._is_running, "まだ実行中")
	assert_eq(_logger._udp_sender, first_sender, "同じUDPSenderインスタンス")


# Test: stop()を連続で呼んでも安全
func test_multiple_stops_are_safe():
	_logger.start()
	_logger.stop()
	_logger.stop()  # 2回目のstop

	assert_false(_logger._is_running, "停止状態のまま")
	assert_null(_logger._udp_sender, "UDPSenderはnullのまま")


# Test: setupはstart後でも設定更新可能
func test_setup_after_start_updates_settings():
	_logger.start()
	_logger.setup("10.0.0.1", 8080)

	assert_eq(_logger._host, "10.0.0.1", "実行中でも設定更新可能")
	assert_eq(_logger._port, 8080, "実行中でもポート更新可能")
	assert_true(_logger._is_running, "setupは実行状態を変更しない")


# Test: デフォルト値でstart可能
func test_start_with_defaults():
	_logger.start()  # setup()なしで直接start

	assert_true(_logger._is_running, "デフォルト値で開始可能")
	assert_eq(_logger._host, "127.0.0.1", "デフォルトホスト使用")
	assert_eq(_logger._port, 9999, "デフォルトポート使用")


# Test: カテゴリ付きログが動作する
func test_category_logging():
	_logger.start()

	var result = _logger.info("test", "network")
	assert_true(result, "カテゴリ付きログが送信される")

	result = _logger.debug("debug test", "performance")
	assert_true(result, "debugでもカテゴリが使える")


# Test: is_running()メソッドが正しく動作
func test_is_running_method():
	assert_false(_logger.is_running(), "初期状態はfalse")

	_logger.start()
	assert_true(_logger.is_running(), "start後はtrue")

	_logger.stop()
	assert_false(_logger.is_running(), "stop後はfalse")


# Test: 全ログレベルが_is_runningをチェック
func test_all_log_levels_check_running_state():
	# 停止中は全てfalse
	assert_false(_logger.trace("test"), "trace: 停止中")
	assert_false(_logger.debug("test"), "debug: 停止中")
	assert_false(_logger.info("test"), "info: 停止中")
	assert_false(_logger.warning("test"), "warning: 停止中")
	assert_false(_logger.error("test"), "error: 停止中")
	assert_false(_logger.critical("test"), "critical: 停止中")

	# 開始後は全てtrue（送信可能）
	_logger.start()
	assert_true(_logger.trace("test"), "trace: 実行中")
	assert_true(_logger.debug("test"), "debug: 実行中")
	assert_true(_logger.info("test"), "info: 実行中")
	assert_true(_logger.warning("test"), "warning: 実行中")
	assert_true(_logger.error("test"), "error: 実行中")
	assert_true(_logger.critical("test"), "critical: 実行中")