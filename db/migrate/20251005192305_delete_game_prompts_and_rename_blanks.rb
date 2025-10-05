class DeleteGamePromptsAndRenameBlanks < ActiveRecord::Migration[8.0]
  def change
    drop_table :game_prompts
    rename_table :blanks, :game_prompts
  end
end
