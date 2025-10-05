class RenameGamePromptsColumnStoryToGame < ActiveRecord::Migration[8.0]
  def change
    rename_column :game_prompts, :story_id, :game_id
  end
end
