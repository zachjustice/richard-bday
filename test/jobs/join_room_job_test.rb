require "test_helper"

class JoinRoomJobTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "jr#{suffix}", status: RoomStatus::WaitingRoom)
    @story = Story.create!(title: "JR #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @room.update!(current_game: @game)
  end

  test "audience user triggers audience count broadcast, not player list" do
    replace_called = false
    append_called = false

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) do |*, **kwargs|
      replace_called = true if kwargs[:target] == "waiting-room-audience-count"
    end
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) do |*, **kwargs|
      append_called = true if kwargs[:target] == "waiting-room"
    end

    audience_user = User.new(name: "AUD#{SecureRandom.hex(4)}", room: @room, role: User::AUDIENCE)
    audience_user.save!(validate: true)

    JoinRoomJob.perform_now(audience_user)

    assert replace_called, "Expected audience count broadcast_replace_to to be called"
    assert_not append_called, "Expected player list broadcast_append_to NOT to be called"
  end

  test "player user triggers player list append, not audience count broadcast" do
    audience_replace_called = false
    append_called = false

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) do |*, **kwargs|
      audience_replace_called = true if kwargs[:target] == "waiting-room-audience-count"
    end
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) do |*, **kwargs|
      append_called = true if kwargs[:target] == "waiting-room"
    end

    player_user = User.new(name: "PLR#{SecureRandom.hex(4)}", room: @room, role: User::PLAYER)
    player_user.save!(validate: true)

    JoinRoomJob.perform_now(player_user)

    assert append_called, "Expected player list broadcast_append_to to be called"
    assert_not audience_replace_called, "Expected audience count broadcast_replace_to NOT to be called"
  end
end
