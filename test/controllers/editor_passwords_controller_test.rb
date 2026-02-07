require "test_helper"

class EditorPasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @editor_session = editor_sessions(:one)
  end

  test "requires editor authentication" do
    patch editor_password_path, params: {
      current_password: "password123",
      new_password: "newpassword123",
      new_password_confirmation: "newpassword123"
    }
    assert_redirected_to editor_login_path
  end

  test "updates password with valid params" do
    sign_in_as_editor(@editor_session)

    patch editor_password_path, params: {
      current_password: "password123",
      new_password: "newpassword456",
      new_password_confirmation: "newpassword456"
    }

    assert_redirected_to editor_settings_path
    assert_equal "Your password has been updated.", flash[:notice]
    assert @editor.reload.authenticate("newpassword456")
  end

  test "rejects incorrect current password" do
    sign_in_as_editor(@editor_session)

    patch editor_password_path, params: {
      current_password: "wrongpassword",
      new_password: "newpassword456",
      new_password_confirmation: "newpassword456"
    }

    assert_redirected_to editor_settings_path
    assert_equal "Current password is incorrect.", flash[:alert]
    assert @editor.reload.authenticate("password123")
  end

  test "rejects mismatched new passwords" do
    sign_in_as_editor(@editor_session)

    patch editor_password_path, params: {
      current_password: "password123",
      new_password: "newpassword456",
      new_password_confirmation: "different789"
    }

    assert_redirected_to editor_settings_path
    assert_equal "New passwords don't match.", flash[:alert]
    assert @editor.reload.authenticate("password123")
  end

  test "rejects blank new password" do
    sign_in_as_editor(@editor_session)

    patch editor_password_path, params: {
      current_password: "password123",
      new_password: "",
      new_password_confirmation: ""
    }

    assert_redirected_to editor_settings_path
    assert_equal "New password can't be blank.", flash[:alert]
  end

  test "rejects short new password" do
    sign_in_as_editor(@editor_session)

    patch editor_password_path, params: {
      current_password: "password123",
      new_password: "short",
      new_password_confirmation: "short"
    }

    assert_redirected_to editor_settings_path
    assert_match(/too short/i, flash[:alert])
    assert @editor.reload.authenticate("password123")
  end

  test "sends notification email on success" do
    sign_in_as_editor(@editor_session)

    assert_enqueued_email_with EditorMailer, :password_changed, args: [ @editor ] do
      patch editor_password_path, params: {
        current_password: "password123",
        new_password: "newpassword456",
        new_password_confirmation: "newpassword456"
      }
    end
  end
end
