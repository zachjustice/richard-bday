class AddVotingStyleToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :voting_style, :string, default: 'vote_once', null: false
    add_column :rooms, :voting_config, :json, default: {}
  end
end
