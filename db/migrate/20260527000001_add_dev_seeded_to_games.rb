class AddDevSeededToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :dev_seeded, :boolean, default: false, null: false
  end
end
