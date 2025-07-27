@tool
extends EditorPlugin

const AUTOLOAD_NAME = "SyncLogger"
const AUTOLOAD_PATH = "res://addons/synclogger/synclogger.gd"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("SyncLogger アドオンが有効化されました")
	print("使用方法:")
	print("  SyncLogger.setup('192.168.1.100', 9999)")
	print("  SyncLogger.log('メッセージ')")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("SyncLogger アドオンが無効化されました")