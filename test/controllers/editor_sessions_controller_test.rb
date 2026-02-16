require "test_helper"

class EditorSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @editor_session = editor_sessions(:one)
  end

  test "valid credentials logs in and redirects" do
    post editor_login_path, params: {
      username: @editor.username,
      password: "password123"
    }

    assert_redirected_to stories_path
    assert cookies[:editor_session_id].present?
  end

  test "invalid password shows error and re-renders" do
    post editor_login_path, params: {
      username: @editor.username,
      password: "wrongpassword"
    }

    assert_response :unprocessable_entity
    assert_equal "Invalid username or password", flash[:alert]
  end

  test "nonexistent username shows error and re-renders" do
    post editor_login_path, params: {
      username: "nonexistent_user",
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_equal "Invalid username or password", flash[:alert]
  end

  test "logout terminates session and redirects" do
    sign_in_as_editor(@editor_session)

    delete editor_logout_path

    assert_redirected_to editor_login_path
    follow_redirect!
    assert_response :success
  end

  test "already logged in redirects to dashboard" do
    sign_in_as_editor(@editor_session)

    get editor_login_path

    assert_redirected_to stories_path
  end
end
