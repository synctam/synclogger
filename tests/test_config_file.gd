extends GutTest
class_name TestConfigFile

# 設定ファイル機能のテスト

const SyncLoggerMain = preload("res://addons/synclogger/synclogger.gd")

var _sync_logger: SyncLoggerMain
var _config_path: String


func before_each():
	_sync_logger = SyncLoggerMain.new()
	add_child_autofree(_sync_logger)
	_config_path = _sync_logger.get_config_file_path()
	# テスト前に設定ファイルを削除
	if FileAccess.file_exists(_config_path):
		DirAccess.remove_absolute(_config_path)


func after_each():
	if _sync_logger:
		_sync_logger.shutdown()
	# テスト後のクリーンアップ
	if FileAccess.file_exists(_config_path):
		DirAccess.remove_absolute(_config_path)
	_sync_logger = null


func test_config_file_disabled_when_no_file():
	# テスト: 設定ファイルがない場合、SyncLoggerが無効化されること
	# テスト用に状態リセット（ファイル削除後の状態再評価）
	_sync_logger._reset_config_state()
	assert_false(_sync_logger.is_config_file_enabled(), "設定ファイルなしでは無効であること")
	assert_false(_sync_logger.info("test message"), "ログ送信が無効であること")


func test_empty_config_file_creates_default():
	# テスト: 空の設定ファイルがデフォルト設定を作成すること
	# 空ファイルを作成
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.close()

	# SyncLoggerを再初期化（テスト用状態リセット）
	_sync_logger._reset_config_state()

	assert_true(_sync_logger.is_config_file_enabled(), "空ファイルで有効化されること")
	assert_true(FileAccess.file_exists(_config_path), "設定ファイルが存在すること")

	# デフォルト設定が書き込まれていることを確認
	var content_file = FileAccess.open(_config_path, FileAccess.READ)
	var content = content_file.get_as_text()
	content_file.close()

	assert_true(content.contains("127.0.0.1"), "デフォルトホストが書き込まれること")
	assert_true(content.contains("9999"), "デフォルトポートが書き込まれること")


func test_invalid_json_overwrites_with_default():
	# テスト: 無効なJSONが正しいJSONで上書きされること
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string("invalid json content")
	file.close()

	# SyncLoggerを再初期化（テスト用状態リセット）
	_sync_logger._reset_config_state()

	assert_true(_sync_logger.is_config_file_enabled(), "無効JSONでも有効化されること")

	# 正しいJSONで上書きされていることを確認
	var content_file = FileAccess.open(_config_path, FileAccess.READ)
	var content = content_file.get_as_text()
	content_file.close()

	var json = JSON.new()
	var parse_result = json.parse(content)
	assert_eq(parse_result, OK, "上書きされたJSONが有効であること")


func test_valid_config_loads_correctly():
	# テスト: 正しい設定ファイルが正常に読み込まれること
	var custom_config = {"host": "192.168.1.100", "port": 8888, "system_capture": false}

	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(custom_config))
	file.close()

	# SyncLoggerを再初期化（テスト用状態リセット）
	_sync_logger._reset_config_state()

	assert_true(_sync_logger.is_config_file_enabled(), "正しい設定で有効化されること")
	assert_eq(_sync_logger.get_host(), "192.168.1.100", "カスタムホストが設定されること")
	assert_eq(_sync_logger.get_port(), 8888, "カスタムポートが設定されること")


func test_compatibility_info_includes_config_status():
	# テスト: 互換性情報に設定ファイル状態が含まれること
	var info = _sync_logger.get_compatibility_info()
	assert_true(info.has("config_file_enabled"), "設定ファイル状態が含まれること")
	assert_false(info.config_file_enabled, "初期状態では無効であること")


func test_file_write_permission_error():
	# テスト: ファイル書き込み権限エラーの処理
	# NOTE: 実際の権限エラーは再現困難なため、動作確認のみ
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string("")
	file.close()

	# 権限エラーのシミュレーションは困難なため、正常ケースで確認
	_sync_logger._ready()
	assert_true(_sync_logger.is_config_file_enabled(), "書き込み可能な場合は有効化されること")


func test_json_non_dictionary_type():
	# テスト: JSONが配列など辞書以外の場合の処理
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string('["not", "a", "dictionary"]')
	file.close()

	_sync_logger._ready()

	assert_true(_sync_logger.is_config_file_enabled(), "非辞書JSONでも有効化されること")
	# デフォルト設定で上書きされていることを確認
	assert_eq(_sync_logger.get_host(), "127.0.0.1", "デフォルトホストが適用されること")
	assert_eq(_sync_logger.get_port(), 9999, "デフォルトポートが適用されること")


func test_partial_config_merging():
	# テスト: 部分設定とデフォルト値のマージ
	var partial_config = {"host": "192.168.1.50", "unknown_key": "should_be_ignored"}

	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(partial_config))
	file.close()

	_sync_logger._ready()

	assert_true(_sync_logger.is_config_file_enabled(), "部分設定で有効化されること")
	assert_eq(_sync_logger.get_host(), "192.168.1.50", "指定されたホストが適用されること")
	assert_eq(_sync_logger.get_port(), 9999, "未指定項目にデフォルト値が適用されること")


func test_all_log_levels_silent_ignore():
	# テスト: 全ログレベルがsilent ignoreされること
	# 設定ファイルなしの状態で確認
	assert_false(_sync_logger.trace("test"), "traceがsilent ignoreされること")
	assert_false(_sync_logger.debug("test"), "debugがsilent ignoreされること")
	assert_false(_sync_logger.info("test"), "infoがsilent ignoreされること")
	assert_false(_sync_logger.warning("test"), "warningがsilent ignoreされること")
	assert_false(_sync_logger.error("test"), "errorがsilent ignoreされること")
	assert_false(_sync_logger.critical("test"), "criticalがsilent ignoreされること")
	assert_false(_sync_logger.log("test"), "logがsilent ignoreされること")


func test_whitespace_only_file():
	# テスト: 空白のみのファイルの処理
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string("   \n\t   \r\n   ")  # 空白、タブ、改行のみ
	file.close()

	_sync_logger._ready()

	assert_true(_sync_logger.is_config_file_enabled(), "空白のみファイルで有効化されること")
	assert_eq(_sync_logger.get_host(), "127.0.0.1", "デフォルト設定が適用されること")


func test_system_capture_config_loading():
	# テスト: システムキャプチャ設定の読み込み
	var config_with_capture = {
		"host": "127.0.0.1",
		"port": 9999,
		"system_capture": false,
		"capture_errors": false,
		"capture_messages": false
	}

	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config_with_capture))
	file.close()

	_sync_logger._ready()

	assert_true(_sync_logger.is_config_file_enabled(), "キャプチャ設定で有効化されること")
	# Godot 4.5+でのみシステムキャプチャ設定をテスト（設定ファイル反映確認）
	if _sync_logger.is_logger_integration_available():
		# system_capture: falseの設定ファイルのため、システムキャプチャは無効になる
		assert_false(_sync_logger.is_system_capture_enabled(), "設定ファイルsystem_capture:falseが反映されること")
		assert_false(_sync_logger.is_capture_errors_enabled(), "設定ファイルcapture_errors:falseが反映されること")
		assert_false(
			_sync_logger.is_capture_messages_enabled(), "設定ファイルcapture_messages:falseが反映されること"
		)


func test_config_file_path_api():
	# テスト: 設定ファイルパスAPIの動作
	var path = _sync_logger.get_config_file_path()
	assert_true(path.begins_with("user://"), "user://で始まること")
	assert_true(path.ends_with(".synclogger.json"), ".synclogger.jsonで終わること")


func test_traditional_setup_after_config_load():
	# テスト: 設定ファイル読み込み後の従来setup()メソッドの動作
	# 空ファイルでデフォルト設定を有効化
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.close()

	_sync_logger._ready()
	assert_true(_sync_logger.is_config_file_enabled(), "設定ファイルで有効化されること")

	# 従来のsetup()を呼び出し
	_sync_logger.setup("192.168.1.200", 8080)
	assert_eq(_sync_logger.get_host(), "192.168.1.200", "従来setup()でホストが変更されること")
	assert_eq(_sync_logger.get_port(), 8080, "従来setup()でポートが変更されること")
