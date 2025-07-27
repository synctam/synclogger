extends GutTest

func test_gut_is_working():
	assert_true(true, "GUTが正常に動作している")
	assert_eq(1, 1, "基本的な等価性テストが動作している")

func test_basic_math():
	assert_eq(2 + 2, 4, "数学計算が正常")
	assert_ne(2 + 2, 5, "不等性テストが正常")