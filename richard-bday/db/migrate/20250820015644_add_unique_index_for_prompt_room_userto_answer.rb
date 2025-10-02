class AddUniqueIndexForPromptRoomUsertoAnswer < ActiveRecord::Migration[8.0]
  def change
    add_index :answers, [ :prompt_id, :room_id, :user_id ], unique: true
  end
end
