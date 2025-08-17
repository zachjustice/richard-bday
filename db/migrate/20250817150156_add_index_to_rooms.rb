class AddIndexToRooms < ActiveRecord::Migration[8.0]
  def change
    add_index :rooms, :code, unique: true
    add_index :users, [ :room_id, :name ], unique: true
  end
end
