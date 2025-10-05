class DropGameColumnFromGamePrompts < ActiveRecord::Migration[8.0]
  def change
    remove_columns :game_prompts, :game_id
  end
end
