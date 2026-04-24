class UpdateRoomEventsReplaceSequenceWithEventTimeAt < ActiveRecord::Migration[8.0]
  def change
    # Add event_time_at timestamp for ordering (replaces sequence)
    add_column :room_events, :event_time_at, :datetime, precision: 6

    # Migrate existing data: set event_time_at to created_at
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE room_events SET event_time_at = created_at
        SQL
      end
    end

    # Make event_time_at not null after data migration
    change_column_null :room_events, :event_time_at, false

    # Remove sequence column
    remove_column :room_events, :sequence, :integer

    # Remove old sequence index
    remove_index :room_events, [ :room_id, :sequence ], if_exists: true

    # Add index for actor queries
    add_index :room_events, [ :actor_type, :actor_id ]

    # Add index for ordering by event_time_at
    add_index :room_events, [ :room_id, :event_time_at ]
  end
end
