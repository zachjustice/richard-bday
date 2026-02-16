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

  test "deletes expired unaccepted invitations older than 30 days" do
    invitation = EditorInvitation.create!(
      email: "expired@test.com",
      token_digest: EditorInvitation.digest("test-token-#{SecureRandom.hex(4)}"),
      expires_at: 31.days.ago,
      accepted_at: nil
    )

    assert_difference "EditorInvitation.count", -1 do
      CleanupExpiredTokensJob.perform_now
    end

    assert_nil EditorInvitation.find_by(id: invitation.id)
  end

  test "preserves accepted invitations even if expired over 30 days" do
    editor = editors(:one)
    invitation = EditorInvitation.create!(
      email: "accepted@test.com",
      token_digest: EditorInvitation.digest("accepted-token-#{SecureRandom.hex(4)}"),
      expires_at: 31.days.ago,
      accepted_at: 32.days.ago,
      editor: editor
    )

    assert_no_difference "EditorInvitation.count" do
      CleanupExpiredTokensJob.perform_now
    end

    assert EditorInvitation.find_by(id: invitation.id)
  end

  test "deletes expired password resets older than 7 days" do
    editor = editors(:one)
    reset = EditorPasswordReset.create!(
      editor: editor,
      token_digest: EditorPasswordReset.digest("reset-token-#{SecureRandom.hex(4)}"),
      expires_at: 8.days.ago
    )

    assert_difference "EditorPasswordReset.count", -1 do
      CleanupExpiredTokensJob.perform_now
    end

    assert_nil EditorPasswordReset.find_by(id: reset.id)
  end
end
