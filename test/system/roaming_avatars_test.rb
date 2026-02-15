require "application_system_test_case"

class RoamingAvatarsTest < ApplicationSystemTestCase
  setup do
    @room = Room.create!(
      code: Room.generate_unique_code,
      discord_instance_id: "test-avatars",
      discord_channel_id: "ch-avatars",
      is_discord_activity: true,
      status: RoomStatus::WaitingRoom
    )
    User.create!(name: "Creator-#{@room.code}", room_id: @room.id, role: User::CREATOR)
    @player1 = User.create!(name: "Alice", room_id: @room.id, role: User::NAVIGATOR, discord_id: "d1", discord_username: "alice")
    @player2 = User.create!(name: "Bob", room_id: @room.id, role: User::PLAYER, discord_id: "d2", discord_username: "bob")
  end

  test "floating avatars appear for users in the room" do
    visit_as_discord_user(@player1, show_room_path)

    assert_text "Welcome, Alice!"
    assert_selector "div#roaming-avatars", visible: :all, wait: 5
    assert_selector "div.roaming-avatar", minimum: 1, wait: 5
  end

  test "floating avatars have accessible labels" do
    visit_as_discord_user(@player1, show_room_path)

    assert_selector ".roaming-avatar[aria-label='Alice']", wait: 5
    assert_selector ".roaming-avatar[aria-label='Bob']", wait: 5
  end

  test "clicking an avatar shows a tooltip with the player name" do
    visit_as_discord_user(@player1, show_room_path)

    avatar = find(".roaming-avatar[aria-label='Bob']", wait: 5)
    avatar.click
    assert_selector ".roaming-avatar-tooltip", text: "Bob", wait: 3
  end

  test "status badges are hidden during WaitingRoom phase" do
    visit_as_discord_user(@player1, show_room_path)

    assert_selector ".roaming-avatar", minimum: 1, wait: 5
    assert_no_selector ".roaming-avatar-status"
  end

  private

  # Set a plain cookie to simulate Discord auth, then visit the target page.
  # Must visit a page on the domain first so the cookie is scoped correctly.
  def visit_as_discord_user(user, path)
    visit new_session_path
    page.execute_script("document.cookie = 'discord_test_user_id=#{user.id}; path=/'")
    visit path
  end
end
