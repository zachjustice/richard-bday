class EditorSettingsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth
  before_action -> { @show_editor_navbar = true }

  def show
    @editor = current_editor
    stories = @editor.stories.includes(:game)

    if params[:query].present?
      stories = stories.where("stories.title LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:query])}%")
    end

    @statistics = stories.map do |story|
      if story.game.present?
        {
          story: story,
          times_played: 1,
          unique_players: User.where(room_id: story.game.room_id).players.count
        }
      else
        { story: story, times_played: 0, unique_players: 0 }
      end
    end
  end
end
