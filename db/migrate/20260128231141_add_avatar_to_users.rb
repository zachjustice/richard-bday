class AddAvatarToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :avatar, :string

    reversible do |dir|
      dir.up do
        # Assign unique avatars to existing users per room
        avatars = %w[
          🦊 🐸 🦄 🐙 🦖 🐝 🦋 🐧 🦀 🐳
          🦩 🐨 🦎 🐲 🦈 🐼 🦉 🐒 🦜 🐬
          🦁 🐢 🐿️ 🦚 🐊 🐴 🦂 🐋 🐺 🦥
        ]
        creator_avatar = "🍆"

        execute("SELECT DISTINCT room_id FROM users").each do |row|
          room_id = row["room_id"]
          available = avatars.dup
          users = execute("SELECT id, role FROM users WHERE room_id = #{room_id} ORDER BY id")
          users.each do |user|
            if user["role"] == "Creator"
              avatar = creator_avatar
            else
              avatar = available.shift || avatars.sample
            end
            execute("UPDATE users SET avatar = '#{avatar}' WHERE id = #{user["id"]}")
          end
        end
      end
    end

    change_column_null :users, :avatar, false
    add_index :users, [ :room_id, :avatar ], unique: true
  end
end
