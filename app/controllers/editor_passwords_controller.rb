class EditorPasswordsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth
  before_action :set_settings_view_data

  rate_limit to: 5, within: 10.minutes, only: [ :update ],
    with: -> {
      flash.now[:alert] = "Too many requests. Please try again later."
      render "editor_settings/show", status: :too_many_requests
    }

  def update
    unless current_editor.authenticate(params[:current_password])
      flash.now[:alert] = "Current password is incorrect."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if params[:new_password].blank?
      flash.now[:alert] = "New password can't be blank."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    unless params[:new_password] == params[:new_password_confirmation]
      flash.now[:alert] = "New passwords don't match."
      render "editor_settings/show", status: :unprocessable_entity
      return
    end

    if current_editor.update(password: params[:new_password])
      EditorMailer.password_changed(current_editor).deliver_later
      redirect_to editor_settings_path, notice: "Your password has been updated."
    else
      flash.now[:alert] = current_editor.errors.full_messages.join(", ")
      render "editor_settings/show", status: :unprocessable_entity
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
