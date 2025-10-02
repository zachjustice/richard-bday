class AddRoomRefToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :room, null: false, foreign_key: true
  end
end
