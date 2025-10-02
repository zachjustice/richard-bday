class ChangeRoomCurrentPromptIndexDefaultColumnFrom1To0 < ActiveRecord::Migration[8.0]
  def change
    change_column_default :rooms, :current_prompt_index, from: 1, to: 0
  end
end
