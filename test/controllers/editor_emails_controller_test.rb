require "test_helper"

class EditorEmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @editor_two = editors(:two)
    @editor_session = editor_sessions(:one)
  end

  # create action tests

  test "create requires editor authentication" do
    post editor_email_path, params: { new_email: "newemail@example.com" }
    assert_redirected_to editor_login_path
  end

  test "create sends confirmation and notification emails" do
    sign_in_as_editor(@editor_session)

    assert_enqueued_emails 2 do
      post editor_email_path, params: { new_email: "newemail@example.com" }
    end

    assert_redirected_to editor_settings_path
    assert_match(/confirmation link/, flash[:notice])
  end

  test "create rejects blank email" do
    sign_in_as_editor(@editor_session)

    post editor_email_path, params: { new_email: "" }

    assert_response :unprocessable_entity
    assert_equal "Email can't be blank.", flash[:alert]
  end

  test "create rejects same email" do
    sign_in_as_editor(@editor_session)

    post editor_email_path, params: { new_email: @editor.email }

    assert_response :unprocessable_entity
    assert_equal "That's already your email address.", flash[:alert]
  end

  test "create rejects email already registered to another editor" do
    sign_in_as_editor(@editor_session)

    post editor_email_path, params: { new_email: @editor_two.email }

    assert_response :unprocessable_entity
    assert_equal "That email is already registered.", flash[:alert]
  end

  test "create stores pending email change" do
    sign_in_as_editor(@editor_session)

    assert_difference("EditorEmailChange.count", 1) do
      post editor_email_path, params: { new_email: "newemail@example.com" }
    end

    email_change = EditorEmailChange.last
    assert_equal @editor, email_change.editor
    assert_equal "newemail@example.com", email_change.new_email
  end

  test "create does not change email immediately" do
    sign_in_as_editor(@editor_session)
    original_email = @editor.email

    post editor_email_path, params: { new_email: "newemail@example.com" }

    assert_equal original_email, @editor.reload.email
  end

  # confirm action tests

  test "confirm updates email with valid token" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )

    get editor_confirm_email_path(token: token)

    assert_redirected_to editor_login_path
    assert_match(/email has been updated/, flash[:notice])
    assert_equal "confirmed@example.com", @editor.reload.email
  end

  test "confirm invalidates all sessions" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )

    assert_difference("@editor.editor_sessions.count", -@editor.editor_sessions.count) do
      get editor_confirm_email_path(token: token)
    end
  end

  test "confirm marks token as used" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )

    get editor_confirm_email_path(token: token)

    assert email_change.reload.used?
  end

  test "confirm rejects invalid token" do
    get editor_confirm_email_path(token: "invalid_token")

    assert_redirected_to editor_login_path
    assert_equal "Invalid confirmation link.", flash[:alert]
  end

  test "confirm rejects expired token" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )
    email_change.update!(expires_at: 1.hour.ago)

    get editor_confirm_email_path(token: token)

    assert_redirected_to editor_login_path
    assert_match(/expired/, flash[:alert])
  end

  test "confirm rejects used token" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )
    email_change.mark_used!

    get editor_confirm_email_path(token: token)

    assert_redirected_to editor_login_path
    assert_match(/expired/, flash[:alert])
  end

  test "confirm rejects if email now taken" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: @editor_two.email
    )

    get editor_confirm_email_path(token: token)

    assert_redirected_to editor_login_path
    assert_match(/now registered/, flash[:alert])
  end

  test "confirm does not require login" do
    email_change, token = EditorEmailChange.create_with_token(
      editor: @editor,
      new_email: "confirmed@example.com"
    )

    get editor_confirm_email_path(token: token)

    assert_redirected_to editor_login_path
    assert_equal "confirmed@example.com", @editor.reload.email
  end
end
