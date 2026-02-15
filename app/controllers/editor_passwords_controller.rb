class EditorPasswordsController < ApplicationController
  include EditorSettingsRenderable
  skip_before_action :require_authentication
  before_action :require_editor_auth
  before_action :set_settings_view_data

  rate_limit to: 5, within: 10.minutes, only: [ :update ],
    with: -> { redirect_to editor_settings_path, alert: "Too many requests. Please try again later." }

  def update
    unless current_editor.authenticate(params[:current_password])
      @password_error = "Current password is incorrect."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if params[:new_password].blank?
      @password_error = "New password can't be blank."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    unless params[:new_password] == params[:new_password_confirmation]
      @password_error = "New passwords don't match."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if current_editor.update(password: params[:new_password])
      EditorMailer.password_changed(current_editor).deliver_later
      redirect_to editor_settings_path, notice: "Your password has been updated."
    else
      @password_error = current_editor.errors.full_messages.join(", ")
      render "editor_settings/show", status: :unprocessable_entity
    end
  end
end
