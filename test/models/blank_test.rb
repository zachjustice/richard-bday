require "test_helper"

class BlankTest < ActiveSupport::TestCase
  test "tags_array parses comma-separated tags correctly" do
    blank = blanks(:one)

    # Multiple tags: "animal,noun"
    assert_equal %w[animal noun], blank.tags_array

    # Whitespace around tags is stripped
    blank.tags = "a, b , c"
    assert_equal %w[a b c], blank.tags_array

    # Empty string returns empty array
    blank.tags = ""
    assert_equal [], blank.tags_array

    # Single tag
    blank.tags = "noun"
    assert_equal %w[noun], blank.tags_array
  end
end
