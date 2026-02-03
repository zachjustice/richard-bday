class CreateRoomEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :room_events do |t|
      t.references :room, null: false, foreign_key: true
      t.references :game, null: true, foreign_key: true
      t.string :event_type, null: false
      t.string :actor_type
      t.integer :actor_id
      t.json :metadata, default: {}
      t.integer :sequence, null: false
      t.timestamps
    end

    add_index :room_events, [ :room_id, :created_at ]
    add_index :room_events, [ :room_id, :sequence ]
  end
end
