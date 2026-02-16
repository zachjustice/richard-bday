require "test_helper"

class EditorInvitationTest < ActiveSupport::TestCase
  test "valid_for_use? returns true for fresh invitation" do
    invitation, _token = EditorInvitation.create_with_token(email: "fresh@example.com")
    assert invitation.valid_for_use?
  end

  test "valid_for_use? returns false for expired invitation" do
    invitation, _token = EditorInvitation.create_with_token(email: "expired@example.com")
    invitation.update!(expires_at: 1.hour.ago)
    assert_not invitation.valid_for_use?
  end

  test "valid_for_use? returns false for accepted invitation" do
    invitation, _token = EditorInvitation.create_with_token(email: "accepted@example.com")
    editor = editors(:one)
    invitation.mark_accepted!(editor)
    assert_not invitation.valid_for_use?
  end
end
