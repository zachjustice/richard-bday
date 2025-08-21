class AddUniqueIndexForPromptRoomUsertoVote < ActiveRecord::Migration[8.0]
  def change
    add_index :votes, [ :prompt_id, :room_id, :user_id ], unique: true
  end
end
