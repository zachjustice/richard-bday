class AddDiscordFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discord_id, :string
    add_column :users, :discord_username, :string
    add_index :users, [ :room_id, :discord_id ], unique: true, where: "discord_id IS NOT NULL"
  end
end
