class EditorMailer < ApplicationMailer
  def invitation(invitation, token)
    @invitation = invitation
    @signup_url = editor_signup_url(token: token)
    @expiry_days = EditorInvitation::EXPIRY_DURATION.in_days.to_i

    mail(
      to: invitation.email,
      subject: "You're invited to become a Blanksies editor!"
    )
  end

  def password_reset(editor, token)
    @editor = editor
    @reset_url = editor_reset_password_url(token: token)
    @expiry_hours = EditorPasswordReset::EXPIRY_DURATION.in_hours.to_i

    mail(
      to: editor.email,
      subject: "Reset your Blanksies password"
    )
  end
end
