class AddVoteTypeToVotes < ActiveRecord::Migration[8.0]
  def up
    add_column :votes, :vote_type, :string, null: false, default: "player"

    # Backfill: audience votes are from users with role='Audience'
    execute <<~SQL
      UPDATE votes SET vote_type = 'audience'
      WHERE user_id IN (SELECT id FROM users WHERE role = 'Audience')
    SQL
  end

  def down
    remove_column :votes, :vote_type
  end
end
