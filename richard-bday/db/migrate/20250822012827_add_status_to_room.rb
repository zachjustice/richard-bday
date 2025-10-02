class AddStatusToRoom < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :status, :string, default: "WaitingRoom"
  end
end
