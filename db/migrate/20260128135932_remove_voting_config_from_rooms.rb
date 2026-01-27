class RemoveVotingConfigFromRooms < ActiveRecord::Migration[8.0]
  def change
    remove_column :rooms, :voting_config, :json
  end
end
