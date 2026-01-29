require "test_helper"

class AvatarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @room = @user.room
    resume_session_as(@room.code, @user.name)
  end

  test "update changes avatar successfully" do
    available = User.available_avatars(@room.id).first

    patch update_avatar_path, params: { avatar: available }, as: :turbo_stream

    assert_response :success
    @user.reload
    assert_equal available, @user.avatar
  end

  test "update fails with invalid avatar" do
    patch update_avatar_path, params: { avatar: "💀" }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Invalid avatar selection"
  end

  test "update fails when avatar already taken" do
    other_user = User.create!(name: "OtherUser", room: @room, role: User::PLAYER)
    taken_avatar = other_user.avatar

    patch update_avatar_path, params: { avatar: taken_avatar }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "already taken"
  end

  test "update requires authentication" do
    end_session

    patch update_avatar_path, params: { avatar: User::AVATARS.first }, as: :turbo_stream

    assert_redirected_to new_session_path
  end
end
