class AddRoomRefToVote < ActiveRecord::Migration[8.0]
  def change
    add_reference :votes, :room, null: false, foreign_key: true
  end
end
