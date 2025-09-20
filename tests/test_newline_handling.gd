extends GutTest
class_name TestNewlineHandling

# 改行処理問題修正のテスト

const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")

var _logger: MainThreadSimpleLogger
var _test_host: String = "127.0.0.1"
var _test_port: int = 9998

func before_each():
	_logger = MainThreadSimpleLogger.new()
	_logger.setup(_test_host, _test_port)

func after_each():
	if _logger:
		_logger.close()
	_logger = null

func test_empty_message_returns_false():
	# テスト: 空メッセージは送信されないこと
	assert_false(_logger.info(""), "空文字列は送信されないこと")
	assert_false(_logger.info("   "), "空白のみは送信されないこと")

func test_newline_only_message_returns_false():
	# テスト: 改行のみメッセージは送信されないこと
	assert_false(_logger.info("\n"), "改行のみは送信されないこと")
	assert_false(_logger.info("\n\n\n"), "複数改行のみは送信されないこと")
	assert_false(_logger.info("\n\n\n\n"), "4つの改行のみは送信されないこと")

func test_leading_trailing_newlines_handled():
	# テスト: 前後の改行が適切に処理されること
	assert_true(_logger.info("\nvalid message\n"), "前後改行付きメッセージが送信されること")
	assert_true(_logger.info("valid message\n"), "末尾改行付きメッセージが送信されること")
	assert_true(_logger.info("\nvalid message"), "先頭改行付きメッセージが送信されること")

func test_whitespace_newline_combination():
	# テスト: 空白と改行の組み合わせが適切に処理されること
	assert_false(_logger.info(" \n \n "), "空白改行組み合わせは送信されないこと")
	assert_true(_logger.info(" \n content \n "), "コンテンツ含む場合は送信されること")

func test_normal_messages_still_work():
	# テスト: 通常のメッセージは正常に動作すること
	assert_true(_logger.info("normal message"), "通常メッセージが送信されること")
	assert_true(_logger.debug("debug info"), "デバッグメッセージが送信されること")
	assert_true(_logger.error("error message"), "エラーメッセージが送信されること")

func test_all_log_levels_handle_newlines():
	# テスト: 全ログレベルで改行処理が動作すること
	assert_false(_logger.trace("\n\n"), "traceレベルで改行のみ拒否")
	assert_false(_logger.debug("\n\n"), "debugレベルで改行のみ拒否")
	assert_false(_logger.info("\n\n"), "infoレベルで改行のみ拒否")
	assert_false(_logger.warning("\n\n"), "warningレベルで改行のみ拒否")
	assert_false(_logger.error("\n\n"), "errorレベルで改行のみ拒否")
	assert_false(_logger.critical("\n\n"), "criticalレベルで改行のみ拒否")

func test_ansi_escape_sequences_removed():
	# テスト: ANSIエスケープシーケンスが除去されること
	var esc = char(0x1b)  # ESC文字を安全に表現
	assert_true(_logger.info(esc + "[1mBold text" + esc + "[0m"), "ANSI太字シーケンス付きメッセージが送信されること")
	assert_true(_logger.info(esc + "[33mYellow text" + esc + "[0m"), "ANSI色シーケンス付きメッセージが送信されること")
	assert_true(_logger.info("[1m6/6 passed.\n" + esc + "[0m"), "GUT風ANSIシーケンス付きメッセージが送信されること")

func test_ansi_only_messages_filtered():
	# テスト: ANSI文字のみのメッセージは送信されないこと
	var esc = char(0x1b)  # ESC文字を安全に表現
	# ANSI文字が正しく除去されて空メッセージになるため、送信されない
	assert_false(_logger.info(esc + "[0m"), "ANSIリセットのみは送信されないこと")
	assert_false(_logger.info(esc + "[1m" + esc + "[0m"), "ANSI開始終了のみは送信されないこと")

func test_control_characters_removed():
	# テスト: その他のコントロール文字も除去されること
	assert_true(_logger.info("Valid" + char(0x08) + "text"), "バックスペース付きメッセージが送信されること")
	assert_true(_logger.info("Valid" + char(0x7f) + "text"), "DEL文字付きメッセージが送信されること")