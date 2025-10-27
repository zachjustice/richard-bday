require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @room = rooms(:one)
  end

  test "should have default role of Player" do
    user = User.new(name: "TestUser", room: @room)
    assert_equal User::PLAYER, user.role
  end

  test "players scope should only return users with Player role" do
    player = User.create!(name: "Player", room: @room, role: User::PLAYER)
    creator = User.create!(name: "Creator", room: @room, role: User::CREATOR)

    players = User.players.where(room: @room)

    assert_includes players, player
    assert_not_includes players, creator
  end
end
