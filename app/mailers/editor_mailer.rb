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

  def password_changed(editor)
    @editor = editor

    mail(
      to: editor.email,
      subject: "Your Blanksies password was changed"
    )
  end

  def email_change_confirmation(email_change, token)
    @email_change = email_change
    @confirmation_url = editor_confirm_email_url(token: token)
    @expiry_hours = EditorEmailChange::EXPIRY_DURATION.in_hours.to_i

    mail(
      to: email_change.new_email,
      subject: "Confirm your new Blanksies email"
    )
  end

  def email_change_requested(editor, new_email)
    @editor = editor
    @new_email = new_email

    mail(
      to: editor.email,
      subject: "Email change requested for your Blanksies account"
    )
  end
end
