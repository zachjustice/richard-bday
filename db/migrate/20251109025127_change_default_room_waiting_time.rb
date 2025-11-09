class ChangeDefaultRoomWaitingTime < ActiveRecord::Migration[8.0]
  def change
    # change the defaults on "time_to_answer_seconds" and "time_to_vote_seconds" to 3 and 2 minutes
    change_column_default :rooms, :time_to_answer_seconds, from: 60, to: 180
    change_column_default :rooms, :time_to_vote_seconds, from: 60, to: 120
  end
end
