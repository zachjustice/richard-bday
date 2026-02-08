class AddDiscordFieldsToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :discord_instance_id, :string
    add_column :rooms, :discord_channel_id, :string
    add_column :rooms, :is_discord_activity, :boolean, default: false
    add_index :rooms, :discord_instance_id, unique: true, where: "discord_instance_id IS NOT NULL"
  end
end
