extends GutTest

var queue: ThreadSafeQueue


func before_each():
	queue = ThreadSafeQueue.new()


func after_each():
	queue = null


func test_can_create_thread_safe_queue():
	assert_not_null(queue, "ThreadSafeQueueが作成できる")


func test_can_push_item_to_queue():
	var item = "test_message"
	queue.push(item)
	assert_false(queue.is_empty(), "アイテムをpushした後はemptyでない")


func test_can_pop_item_from_queue():
	var test_item = "test_message"
	queue.push(test_item)

	var popped_item = queue.pop()
	assert_eq(popped_item, test_item, "pushしたアイテムがpopで取得できる")


func test_queue_is_empty_after_pop():
	var test_item = "test_message"
	queue.push(test_item)
	queue.pop()

	assert_true(queue.is_empty(), "popした後はemptyになる")


func test_pop_from_empty_queue_returns_null():
	var result = queue.pop()
	assert_null(result, "空のキューからpopするとnullが返る")


func test_queue_is_fifo():
	queue.push("first")
	queue.push("second")
	queue.push("third")

	assert_eq(queue.pop(), "first", "FIFO: 最初にpushしたものが最初にpopされる")
	assert_eq(queue.pop(), "second", "FIFO: 2番目にpushしたものが2番目にpopされる")
	assert_eq(queue.pop(), "third", "FIFO: 3番目にpushしたものが3番目にpopされる")
