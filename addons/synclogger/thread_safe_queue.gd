class_name ThreadSafeQueue
extends RefCounted

var _queue: Array = []
var _mutex: Mutex


func _init():
	_mutex = Mutex.new()


func push(item) -> void:
	_mutex.lock()
	_queue.append(item)
	_mutex.unlock()


func pop():
	_mutex.lock()
	var result = null
	if not _queue.is_empty():
		result = _queue.pop_front()
	_mutex.unlock()
	return result


func is_empty() -> bool:
	_mutex.lock()
	var empty = _queue.is_empty()
	_mutex.unlock()
	return empty
