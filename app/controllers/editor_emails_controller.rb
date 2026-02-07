class EditorEmailsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth, only: :create

  rate_limit to: 5, within: 10.minutes, only: [ :create ],
    with: -> { redirect_to editor_settings_path, alert: "Too many requests. Please try again later." }

  def create
    new_email = params[:new_email]&.downcase&.strip

    if new_email.blank?
      redirect_to editor_settings_path, alert: "Email can't be blank."
      return
    end

    if new_email == current_editor.email
      redirect_to editor_settings_path, alert: "That's already your email address."
      return
    end

    if Editor.where.not(id: current_editor.id).exists?(email: new_email)
      redirect_to editor_settings_path, alert: "That email is already registered."
      return
    end

    email_change, token = EditorEmailChange.create_with_token(editor: current_editor, new_email: new_email)

    if token
      EditorMailer.email_change_confirmation(email_change, token).deliver_later
      EditorMailer.email_change_requested(current_editor, new_email).deliver_later

      unless Rails.env.production?
        confirmation_url = editor_confirm_email_url(token: token)
        Rails.logger.info "Email change confirmation link (dev only): #{confirmation_url}"
      end

      redirect_to editor_settings_path, notice: "A confirmation link has been sent to #{new_email}."
    else
      redirect_to editor_settings_path, alert: email_change.errors.full_messages.join(", ")
    end
  end

  def confirm
    email_change = EditorEmailChange.find_by_token(params[:token])

    if email_change.nil?
      redirect_to editor_login_path, alert: "Invalid confirmation link."
      return
    end

    unless email_change.valid_for_use?
      redirect_to editor_login_path, alert: "This confirmation link has expired or already been used."
      return
    end

    if Editor.where.not(id: email_change.editor_id).exists?(email: email_change.new_email)
      redirect_to editor_login_path, alert: "That email is now registered to another account."
      return
    end

    if email_change.editor.update(email: email_change.new_email)
      email_change.mark_used!
      email_change.editor.editor_sessions.destroy_all
      redirect_to editor_login_path, notice: "Your email has been updated. Please sign in."
    else
      redirect_to editor_login_path, alert: "Unable to update email. Please try again."
    end
  end
end
