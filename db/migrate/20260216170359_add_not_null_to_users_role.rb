class AddNotNullToUsersRole < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE users SET role = 'Player' WHERE role IS NULL"
    change_column_null :users, :role, false
  end

  def down
    change_column_null :users, :role, true
  end
end
