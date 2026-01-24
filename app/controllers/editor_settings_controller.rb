class EditorSettingsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth

  def edit
    @editor = current_editor
  end

  def update
    @editor = current_editor

    if !@editor.authenticate(params[:current_password])
      flash.now[:alert] = "Current password is incorrect"
      return render :edit, status: :unprocessable_entity
    end

    if params[:password].blank?
      flash.now[:alert] = "New password cannot be blank"
      return render :edit, status: :unprocessable_entity
    end

    if @editor.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to edit_editor_settings_path, notice: "Password updated successfully"
    else
      flash.now[:alert] = @editor.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end
end
