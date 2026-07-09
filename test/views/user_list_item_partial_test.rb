# frozen_string_literal: true

require "test_helper"

class UserListItemPartialTest < ActionView::TestCase
  test "explicit accolade local wins over fallback" do
    html = render partial: "rooms/partials/user_list_item", locals: { user: users(:one), accolade: "custom_tag" }

    assert_includes html, 'data-accolade="custom_tag"'
  end

  test "emits empty data-accolade when no current_game and no local passed" do
    user = users(:one)
    # users(:one) belongs to room in WaitingRoom — no game yet
    assert_nil user.room.current_game

    html = render partial: "rooms/partials/user_list_item", locals: { user: user }

    assert_includes html, 'data-accolade=""'
  end
end
