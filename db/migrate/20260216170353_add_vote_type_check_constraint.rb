class AddVoteTypeCheckConstraint < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE votes SET vote_type = 'player' WHERE vote_type IS NULL OR vote_type NOT IN ('player', 'audience')"
    add_check_constraint :votes, "vote_type IN ('player', 'audience')", name: "check_vote_type_values"
  end

  def down
    remove_check_constraint :votes, name: "check_vote_type_values"
  end
end
