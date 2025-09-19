@tool
extends EditorPlugin

const AUTOLOAD_NAME = "SyncLogger"
const AUTOLOAD_PATH = "res://addons/synclogger/synclogger.gd"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("SyncLogger addon enabled")
	print("Usage:")
	print("  SyncLogger.setup('127.0.0.1', 9999)")
	print("  SyncLogger.log('message')")
	print("System log capture options:")
	print("  SyncLogger.enable_system_log_capture(true/false)")
	print("  SyncLogger.set_capture_errors(true/false)")
	print("  SyncLogger.set_capture_messages(true/false)")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("SyncLogger addon disabled")