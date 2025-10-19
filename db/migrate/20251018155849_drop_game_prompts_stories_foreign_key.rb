class DropGamePromptsStoriesForeignKey < ActiveRecord::Migration[8.0]
  def change
    if foreign_key_exists?(:game_prompts, :stories)
      remove_foreign_key :game_prompts, :stories
    end
    add_foreign_key :game_prompts, :games
  end
end
