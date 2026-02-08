require "test_helper"

class DiscordActivityTokenTest < ActiveSupport::TestCase
  test "creates token with digest and expiry" do
    user = users(:one)
    token_record = DiscordActivityToken.create_for_user(user)

    assert token_record.persisted?
    assert token_record.token.present?
    assert token_record.token_digest.present?
    assert token_record.expires_at > Time.current
  end

  test "finds token by plain text" do
    user = users(:one)
    created = DiscordActivityToken.create_for_user(user)

    found = DiscordActivityToken.find_by_token(created.token)
    assert_equal created.id, found.id
  end

  test "returns nil for blank token" do
    assert_nil DiscordActivityToken.find_by_token(nil)
    assert_nil DiscordActivityToken.find_by_token("")
  end

  test "valid_token? returns false when expired" do
    user = users(:one)
    token_record = DiscordActivityToken.create_for_user(user)
    token_record.update!(expires_at: 1.hour.ago)

    assert_not token_record.valid_token?
  end

  test "valid_token? returns true when not expired" do
    user = users(:one)
    token_record = DiscordActivityToken.create_for_user(user)

    assert token_record.valid_token?
  end

  test "refresh extends expiry" do
    user = users(:one)
    token_record = DiscordActivityToken.create_for_user(user)
    original_expiry = token_record.expires_at

    travel_to 1.hour.from_now do
      token_record.refresh!
      assert token_record.expires_at > original_expiry
    end
  end
end
