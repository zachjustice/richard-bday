require "test_helper"

class EditorPasswordResetTest < ActiveSupport::TestCase
  setup do
    @editor = editors(:one)
  end

  test "create_with_token invalidates previous unused resets" do
    first_reset, _token1 = EditorPasswordReset.create_with_token(editor: @editor)
    assert_nil first_reset.used_at

    _second_reset, _token2 = EditorPasswordReset.create_with_token(editor: @editor)
    assert_not_nil first_reset.reload.used_at
  end

  test "valid_for_use? returns true for fresh reset" do
    reset, _token = EditorPasswordReset.create_with_token(editor: @editor)
    assert reset.valid_for_use?
  end

  test "valid_for_use? returns false for expired reset" do
    reset, _token = EditorPasswordReset.create_with_token(editor: @editor)
    reset.update!(expires_at: 1.hour.ago)
    assert_not reset.valid_for_use?
  end

  test "valid_for_use? returns false for used reset" do
    reset, _token = EditorPasswordReset.create_with_token(editor: @editor)
    reset.mark_used!
    assert_not reset.valid_for_use?
  end

  test "mark_used! sets used_at" do
    reset, _token = EditorPasswordReset.create_with_token(editor: @editor)
    assert_nil reset.used_at
    reset.mark_used!
    assert_not_nil reset.reload.used_at
  end
end
