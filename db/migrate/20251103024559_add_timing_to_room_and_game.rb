class AddTimingToRoomAndGame < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :time_to_answer_seconds, :int, default: 60, null: false
    add_column :rooms, :time_to_vote_seconds, :int, default: 60, null: false
    add_column :games, :next_game_phase_time, :datetime, null: true
  end
end
