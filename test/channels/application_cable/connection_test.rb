require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  setup do
    @room = rooms(:one)
    @user = User.create!(name: "CableTestUser", room: @room, role: User::PLAYER)
    @session = Session.create!(user: @user, user_agent: "test", ip_address: "127.0.0.1")
  end

  test "connects with valid player_session_id cookie" do
    cookies.signed[:player_session_id] = @session.id
    connect
    assert_equal @user.id, connection.current_user.id
  end

  test "rejects connection with legacy session_id cookie (migration complete)" do
    cookies.signed[:session_id] = @session.id
    assert_reject_connection { connect }
  end

  test "rejects connection with no cookies" do
    assert_reject_connection { connect }
  end

  test "rejects connection with invalid session id" do
    cookies.signed[:player_session_id] = -999
    assert_reject_connection { connect }
  end
end
