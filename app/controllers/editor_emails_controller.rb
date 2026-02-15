class EditorEmailsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth, only: :create
  before_action :set_settings_view_data, only: :create

  rate_limit to: 5, within: 10.minutes, only: [ :create ],
    with: -> {
      flash.now[:alert] = "Too many requests. Please try again later."
      render "editor_settings/show", status: :too_many_requests
    }

  def create
    new_email = params[:new_email]&.downcase&.strip

    if new_email.blank?
      flash.now[:alert] = "Email can't be blank."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if new_email == current_editor.email
      flash.now[:alert] = "That's already your email address."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if Editor.where.not(id: current_editor.id).exists?(email: new_email)
      flash.now[:alert] = "That email is already registered."
      render "editor_settings/show", status: :unprocessable_entity
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
      flash.now[:alert] = email_change.errors.full_messages.join(", ")
      render "editor_settings/show", status: :unprocessable_entity
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

  private

  def set_settings_view_data
    @show_editor_navbar = true
    @statistics = current_editor.stories.includes(:game).map do |story|
      if story.game.present?
        { story: story, times_played: 1, unique_players: User.where(room_id: story.game.room_id).players.count }
      else
        { story: story, times_played: 0, unique_players: 0 }
      end
    end
  end
end
