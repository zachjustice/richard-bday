require "test_helper"

class PromptTest < ActiveSupport::TestCase
  setup do
    @editor_one = editors(:one)
    @editor_two = editors(:two)
    @prompt_one = prompts(:one)   # owned by editor_one
    @prompt_three = prompts(:three) # owned by editor_one
  end

  # owned_by? tests
  test "owned_by? returns true for prompt creator" do
    assert @prompt_one.owned_by?(@editor_one)
  end

  test "owned_by? returns false for non-creator" do
    assert_not @prompt_one.owned_by?(@editor_two)
  end

  test "owned_by? returns false for nil editor" do
    assert_not @prompt_one.owned_by?(nil)
  end

  test "owned_by? returns false for nil creator_id" do
    # Simulate a nil creator_id without going through validation
    prompt = Prompt.new(description: "test", tags: "test", creator: @editor_one)
    prompt.creator_id = nil
    assert_not prompt.owned_by?(@editor_one)
  end

  # Validation tests
  test "prompt requires description" do
    prompt = Prompt.new(tags: "test", creator: @editor_one)
    assert_not prompt.valid?
    assert_includes prompt.errors[:description], "can't be blank"
  end

  test "prompt requires tags" do
    prompt = Prompt.new(description: "Test description", creator: @editor_one)
    assert_not prompt.valid?
    assert_includes prompt.errors[:tags], "can't be blank"
  end

  test "prompt description must be unique" do
    existing = prompts(:one)
    duplicate = Prompt.new(description: existing.description, tags: "test", creator: @editor_one)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:description], "has already been taken"
  end

  # tags_array tests
  test "tags_array returns array of tags" do
    prompt = Prompt.new(description: "Test", tags: "one, two, three")
    assert_equal [ "one", "two", "three" ], prompt.tags_array
  end

  test "tags_array strips whitespace" do
    prompt = Prompt.new(description: "Test", tags: "  one  ,  two  ")
    assert_equal [ "one", "two" ], prompt.tags_array
  end

  test "tags_array rejects blank entries" do
    prompt = Prompt.new(description: "Test", tags: "one,,two,")
    assert_equal [ "one", "two" ], prompt.tags_array
  end
end
