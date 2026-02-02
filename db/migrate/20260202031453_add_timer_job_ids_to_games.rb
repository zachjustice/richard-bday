class AddTimerJobIdsToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :answering_timer_job_id, :string
    add_column :games, :voting_timer_job_id, :string
  end
end
