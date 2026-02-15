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

  # Avatar validations
  test "avatar is required when no available avatars" do
    room = Room.create!(code: "noavatars", status: "WaitingRoom")
    # Fill up all avatars
    User::AVATARS.each_with_index do |avatar, i|
      User.create!(name: "Player#{i}", room: room, role: User::PLAYER, avatar: avatar)
    end

    # Try to create a user when no avatars are available
    user = User.new(name: "NoAvatar", room: room, role: User::PLAYER)
    assert_not user.valid?
    assert_includes user.errors[:avatar], "can't be blank"
  end

  test "avatar must be from AVATARS or CREATOR_AVATAR" do
    user = users(:one)
    user.avatar = "💀"
    assert_not user.valid?
  end

  test "avatar must be unique within room" do
    existing = users(:one)
    new_user = User.new(name: "New", room: existing.room, role: User::PLAYER, avatar: existing.avatar)
    assert_not new_user.valid?
    assert_includes new_user.errors[:avatar], "has already been taken"
  end

  # Avatar assignment callback
  test "assigns random avatar on create for player" do
    room = rooms(:two)
    user = User.create!(name: "NewPlayer", room: room, role: User::PLAYER)
    assert_includes User::AVATARS, user.avatar
  end

  test "assigns creator avatar for creator role" do
    room = rooms(:two)
    user = User.create!(name: "Creator", room: room, role: User::CREATOR)
    assert_equal User::CREATOR_AVATAR, user.avatar
  end

  # available_avatars class method
  test "available_avatars returns avatars not taken in room" do
    room = rooms(:one)
    taken = User.where(room: room).pluck(:avatar)
    available = User.available_avatars(room.id)

    assert_equal User::AVATARS - taken, available
  end

  # Room capacity
  test "cannot create user when room is at max capacity" do
    room = Room.create!(code: "full", status: "WaitingRoom")

    User::MAX_PLAYERS.times do |i|
      User.create!(name: "Player#{i}", room: room, role: User::PLAYER)
    end

    new_user = User.new(name: "TooMany", room: room, role: User::PLAYER)
    assert_not new_user.valid?
    assert_includes new_user.errors[:base], "Room is full (max #{User::MAX_PLAYERS} players)"
  end

  test "creator can still join full room" do
    room = Room.create!(code: "fullcreator", status: "WaitingRoom")

    User::MAX_PLAYERS.times do |i|
      User.create!(name: "Player#{i}", room: room, role: User::PLAYER)
    end

    creator = User.new(name: "RoomCreator", room: room, role: User::CREATOR)
    assert creator.valid?, "Creator should be able to join a full room"
  end

  # Slur filtering
  test "name cannot contain slurs" do
    SlurDetectorService.stub_any_instance(:contains_slur?, true) do
      user = User.new(name: "BadName", room: @room, role: User::PLAYER)
      assert_not user.valid?
      assert_includes user.errors[:name], "contains inappropriate language"
    end
  end

  test "name allows normal text" do
    user = User.new(name: "GoodName", room: @room, role: User::PLAYER)
    assert user.valid?, "User with normal name should be valid: #{user.errors.full_messages}"
  end

  # --- Audience tests ---

  test "audience scope returns only audience users" do
    room = Room.create!(code: "audscope", status: "WaitingRoom")
    player = User.create!(name: "Player1", room: room, role: User::PLAYER)
    audience_user = User.create!(name: "Audience1", room: room, role: User::AUDIENCE)

    audience_users = User.audience.where(room: room)
    assert_includes audience_users, audience_user
    assert_not_includes audience_users, player
  end

  test "audience? returns true for audience role" do
    room = Room.create!(code: "audpred", status: "WaitingRoom")
    user = User.create!(name: "AudUser", room: room, role: User::AUDIENCE)
    assert user.audience?
  end

  test "audience? returns false for player role" do
    room = Room.create!(code: "audpred2", status: "WaitingRoom")
    user = User.create!(name: "PlayerUser", room: room, role: User::PLAYER)
    assert_not user.audience?
  end

  test "audience users get audience avatar assigned" do
    room = Room.create!(code: "audavt", status: "WaitingRoom")
    user = User.create!(name: "AudAvatar", room: room, role: User::AUDIENCE)
    assert_equal User::AUDIENCE_AVATAR, user.avatar
  end

  test "audience users bypass name uniqueness validation" do
    room = Room.create!(code: "audname", status: "WaitingRoom")
    user1 = User.create!(name: "SameName", room: room, role: User::AUDIENCE)
    user2 = User.new(name: "SameName", room: room, role: User::AUDIENCE)
    assert user2.valid?, "Audience users should allow duplicate names: #{user2.errors.full_messages}"
  end

  test "audience users bypass avatar uniqueness validation" do
    room = Room.create!(code: "audavtu", status: "WaitingRoom")
    user1 = User.create!(name: "Aud1", room: room, role: User::AUDIENCE)
    user2 = User.new(name: "Aud2", room: room, role: User::AUDIENCE)
    assert user2.valid?, "Audience users should allow duplicate avatars: #{user2.errors.full_messages}"
    assert_equal User::AUDIENCE_AVATAR, user1.avatar
    assert_equal User::AUDIENCE_AVATAR, user2.avatar
  end

  test "audience capacity is enforced" do
    room = Room.create!(code: "audcap", status: "WaitingRoom")

    User::MAX_AUDIENCE.times do |i|
      User.create!(name: "Aud#{i}", room: room, role: User::AUDIENCE)
    end

    overflow = User.new(name: "AudOverflow", room: room, role: User::AUDIENCE)
    assert_not overflow.valid?
    assert_includes overflow.errors[:base], "Audience is full (max #{User::MAX_AUDIENCE})"
  end
end
