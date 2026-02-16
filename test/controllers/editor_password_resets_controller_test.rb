require "test_helper"

class EditorPasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
  end

  # create (forgot password) tests

  test "forgot password with existing email sends reset email" do
    assert_enqueued_email_with EditorMailer, :password_reset, args: ->(args) { args.first == @editor } do
      post editor_forgot_password_path, params: { email: @editor.email }
    end

    assert_redirected_to editor_login_path
    assert_match /reset instructions/, flash[:notice]
  end

  test "forgot password with nonexistent email shows same success message" do
    post editor_forgot_password_path, params: { email: "nobody@example.com" }

    assert_redirected_to editor_login_path
    assert_match /reset instructions/, flash[:notice]
  end

  test "per-email rate limit exceeded rejects with message" do
    # Create 3 recent resets to trigger per-email rate limit
    3.times do
      EditorPasswordReset.create_with_token(editor: @editor)
    end

    post editor_forgot_password_path, params: { email: @editor.email }

    assert_redirected_to editor_forgot_password_path
    assert_match /Too many reset requests/, flash[:alert]
  end

  # edit (reset form) tests

  test "edit with valid token renders password reset form" do
    _reset, token = EditorPasswordReset.create_with_token(editor: @editor)

    get editor_reset_password_path(token: token)

    assert_response :success
  end

  test "edit with invalid token redirects" do
    get editor_reset_password_path(token: "bogus_token")

    assert_redirected_to editor_login_path
    assert_equal "Invalid reset link.", flash[:alert]
  end

  test "edit with expired token redirects" do
    reset, token = EditorPasswordReset.create_with_token(editor: @editor)
    reset.update!(expires_at: 1.hour.ago)

    get editor_reset_password_path(token: token)

    assert_redirected_to editor_login_path
    assert_match /expired/, flash[:alert]
  end

  test "edit with used token redirects" do
    reset, token = EditorPasswordReset.create_with_token(editor: @editor)
    reset.mark_used!

    get editor_reset_password_path(token: token)

    assert_redirected_to editor_login_path
    assert_match /already been used/, flash[:alert]
  end

  # update tests

  test "update with valid token updates password and destroys sessions" do
    _reset, token = EditorPasswordReset.create_with_token(editor: @editor)

    patch editor_reset_password_path(token: token), params: { password: "newpassword456" }

    assert_redirected_to editor_login_path
    assert_match /Password updated/, flash[:notice]
    assert @editor.reload.authenticate("newpassword456")
    assert_equal 0, @editor.editor_sessions.count
  end

  test "update with blank password re-renders with error" do
    _reset, token = EditorPasswordReset.create_with_token(editor: @editor)

    patch editor_reset_password_path(token: token), params: { password: "" }

    assert_response :unprocessable_entity
  end

  test "update with expired token redirects" do
    reset, token = EditorPasswordReset.create_with_token(editor: @editor)
    reset.update!(expires_at: 1.hour.ago)

    patch editor_reset_password_path(token: token), params: { password: "newpassword456" }

    assert_redirected_to editor_login_path
    assert_match /Invalid or expired/, flash[:alert]
    assert @editor.reload.authenticate("password123")
  end
end
