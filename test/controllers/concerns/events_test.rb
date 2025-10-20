require "test_helper"
class AnswerTest < ActiveSupport::TestCase
  test "Generates events" do
    e = Events.create_user_joined_room_event("Obama")
    assert_equal e[:messageType], Events::MessageType::NewUser
    assert_equal e[:newUser], "Obama"
  end
end
