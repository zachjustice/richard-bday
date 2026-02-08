require "test_helper"

class CleanupExpiredTokensJobTest < ActiveSupport::TestCase
  test "cleans up expired discord activity tokens" do
    user = users(:one)
    expired = DiscordActivityToken.create_for_user(user)
    expired.update!(expires_at: 1.hour.ago)

    valid = DiscordActivityToken.create_for_user(user)

    assert_difference "DiscordActivityToken.count", -1 do
      CleanupExpiredTokensJob.perform_now
    end

    assert_nil DiscordActivityToken.find_by(id: expired.id)
    assert DiscordActivityToken.find_by(id: valid.id)
  end

  test "preserves non-expired discord activity tokens" do
    user = users(:one)
    token = DiscordActivityToken.create_for_user(user)

    assert_no_difference "DiscordActivityToken.count" do
      CleanupExpiredTokensJob.perform_now
    end

    assert DiscordActivityToken.find_by(id: token.id)
  end
end
