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

  test "connects with valid cable token" do
    cable_token = SecureRandom.urlsafe_base64(32)
    with_memory_cache do
      Rails.cache.write("cable_token:#{cable_token}", @user.id, expires_in: 30.seconds)
      connect params: { cable_token: cable_token }
      assert_equal @user.id, connection.current_user.id
    end
  end

  test "rejects connection with invalid cable token" do
    assert_reject_connection { connect params: { cable_token: "invalid" } }
  end

  test "rejects connection with expired cable token" do
    cable_token = SecureRandom.urlsafe_base64(32)
    with_memory_cache do
      Rails.cache.write("cable_token:#{cable_token}", @user.id, expires_in: 1.second)
      sleep 1.1
      assert_reject_connection { connect params: { cable_token: cable_token } }
    end
  end

  # Audience connection tests

  test "audience user connect sets is_active to true" do
    audience_user = User.create!(name: "AudienceConn", room: @room, role: User::AUDIENCE, is_active: false)
    audience_session = Session.create!(user: audience_user, user_agent: "test", ip_address: "127.0.0.1")

    cookies.signed[:player_session_id] = audience_session.id
    connect

    audience_user.reload
    assert audience_user.is_active
  end

  test "audience user disconnect sets is_active to false" do
    audience_user = User.create!(name: "AudienceDisc", room: @room, role: User::AUDIENCE, is_active: true)
    audience_session = Session.create!(user: audience_user, user_agent: "test", ip_address: "127.0.0.1")

    cookies.signed[:player_session_id] = audience_session.id
    connect
    disconnect

    audience_user.reload
    refute audience_user.is_active
  end

  test "audience user connect does not broadcast player list append" do
    audience_user = User.create!(name: "AudienceNoBc", room: @room, role: User::AUDIENCE, is_active: false)
    audience_session = Session.create!(user: audience_user, user_agent: "test", ip_address: "127.0.0.1")

    appended = false
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| appended = true }

    cookies.signed[:player_session_id] = audience_session.id
    connect

    refute appended, "broadcast_append_to should not be called for audience users"
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
