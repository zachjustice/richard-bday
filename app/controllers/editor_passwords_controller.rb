class EditorPasswordsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth

  rate_limit to: 5, within: 10.minutes, only: [ :update ],
    with: -> { redirect_to editor_settings_path, alert: "Too many requests. Please try again later." }

  def update
    unless current_editor.authenticate(params[:current_password])
      redirect_to editor_settings_path, alert: "Current password is incorrect."
      return
    end

    if params[:new_password].blank?
      redirect_to editor_settings_path, alert: "New password can't be blank."
      return
    end

    unless params[:new_password] == params[:new_password_confirmation]
      redirect_to editor_settings_path, alert: "New passwords don't match."
      return
    end

    if current_editor.update(password: params[:new_password])
      EditorMailer.password_changed(current_editor).deliver_later
      redirect_to editor_settings_path, notice: "Your password has been updated."
    else
      redirect_to editor_settings_path, alert: current_editor.errors.full_messages.join(", ")
    end
  end
end
