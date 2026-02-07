require "test_helper"

class EditorEmailChangeTest < ActiveSupport::TestCase
  setup do
    @editor = editors(:one)
  end

  test "create_with_token generates valid token" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "new@example.com"
    )

    assert email_change.persisted?
    assert_not_nil token
    assert_equal "new@example.com", email_change.new_email
  end

  test "create_with_token invalidates previous pending requests" do
    first_change, _ = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "first@example.com"
    )

    second_change, _ = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "second@example.com"
    )

    assert first_change.reload.used?
    assert_not second_change.reload.used?
  end

  test "find_by_token finds correct record" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "new@example.com"
    )

    found = EditorEmailChange.find_by_token(token)
    assert_equal email_change, found
  end

  test "find_by_token returns nil for blank token" do
    assert_nil EditorEmailChange.find_by_token("")
    assert_nil EditorEmailChange.find_by_token(nil)
  end

  test "valid_for_use returns true for fresh token" do
    email_change, _ = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "new@example.com"
    )

    assert email_change.valid_for_use?
  end

  test "expired returns true after expiry duration" do
    email_change, _ = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "new@example.com"
    )
    email_change.update!(expires_at: 1.hour.ago)

    assert email_change.expired?
    assert_not email_change.valid_for_use?
  end

  test "normalizes new_email to lowercase" do
    email_change, _ = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "  NEW@EXAMPLE.COM  "
    )

    assert_equal "new@example.com", email_change.new_email
  end

  test "validates new_email format" do
    email_change = EditorEmailChange.new(
      editor: @editor,
      new_email: "not-an-email",
      token_digest: EditorEmailChange.digest("test")
    )

    assert_not email_change.valid?
    assert email_change.errors[:new_email].any?
  end

  test "validates new_email presence" do
    email_change = EditorEmailChange.new(
      editor: @editor,
      new_email: nil,
      token_digest: EditorEmailChange.digest("test")
    )

    assert_not email_change.valid?
    assert email_change.errors[:new_email].any?
  end
end
