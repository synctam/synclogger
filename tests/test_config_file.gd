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
	assert_false(_sync_logger.is_config_file_enabled(), "設定ファイルなしでは無効であること")
	assert_false(_sync_logger.info("test message"), "ログ送信が無効であること")

func test_empty_config_file_creates_default():
	# テスト: 空の設定ファイルがデフォルト設定を作成すること
	# 空ファイルを作成
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.close()

	# SyncLoggerを再初期化
	_sync_logger._ready()

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

	# SyncLoggerを再初期化
	_sync_logger._ready()

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
	var custom_config = {
		"host": "192.168.1.100",
		"port": 8888,
		"system_capture": false
	}

	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(custom_config))
	file.close()

	# SyncLoggerを再初期化
	_sync_logger._ready()

	assert_true(_sync_logger.is_config_file_enabled(), "正しい設定で有効化されること")
	assert_eq(_sync_logger.get_host(), "192.168.1.100", "カスタムホストが設定されること")
	assert_eq(_sync_logger.get_port(), 8888, "カスタムポートが設定されること")

func test_compatibility_info_includes_config_status():
	# テスト: 互換性情報に設定ファイル状態が含まれること
	var info = _sync_logger.get_compatibility_info()
	assert_true(info.has("config_file_enabled"), "設定ファイル状態が含まれること")
	assert_false(info.config_file_enabled, "初期状態では無効であること")