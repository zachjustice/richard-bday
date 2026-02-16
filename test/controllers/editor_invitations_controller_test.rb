require "test_helper"

class EditorInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation, @token = EditorInvitation.create_with_token(email: "neweditor@example.com")
  end

  test "show with valid token renders signup form" do
    get editor_signup_path(token: @token)

    assert_response :success
  end

  test "show with invalid token redirects with alert" do
    get editor_signup_path(token: "bogus_token")

    assert_redirected_to editor_login_path
    assert_equal "Invalid invitation link.", flash[:alert]
  end

  test "show with expired token redirects with message" do
    @invitation.update!(expires_at: 1.day.ago)

    get editor_signup_path(token: @token)

    assert_redirected_to editor_login_path
    assert_match /expired/, flash[:alert]
  end

  test "show with accepted token redirects with message" do
    @invitation.mark_accepted!(editors(:one))

    get editor_signup_path(token: @token)

    assert_redirected_to editor_login_path
    assert_match /already been used/, flash[:alert]
  end

  test "create with valid params creates editor and starts session" do
    assert_difference("Editor.count", 1) do
      post editor_signup_path(token: @token), params: {
        editor: {
          username: "new_editor",
          password: "securepassword123"
        }
      }
    end

    assert_redirected_to stories_path
    @invitation.reload
    assert @invitation.accepted?
  end

  test "create with invalid editor params re-renders with errors" do
    assert_no_difference("Editor.count") do
      post editor_signup_path(token: @token), params: {
        editor: {
          username: "",
          password: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
