require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "Create Room" do
    r = Room.new(code: "asdf")
    assert r.save
  end
end
