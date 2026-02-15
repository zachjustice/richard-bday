module EditorSettingsRenderable
  extend ActiveSupport::Concern

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
