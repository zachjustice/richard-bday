class AddCurrentPromptIndexToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :current_prompt_index, :integer, default: 1, null: false
  end
end
