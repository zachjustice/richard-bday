require "test_helper"

class EditorTest < ActiveSupport::TestCase
  test "email normalization downcases and strips whitespace" do
    editor = Editor.new(
      username: "normtest",
      email: "  TEST@EXAMPLE.COM  ",
      password: "password123",
      password_confirmation: "password123"
    )
    editor.valid?
    assert_equal "test@example.com", editor.email
  end
end
