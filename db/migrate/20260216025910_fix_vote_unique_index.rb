class FixVoteUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :votes, name: "idx_votes_prompt_user_answer_unique"
    add_index :votes, [ :game_prompt_id, :user_id, :answer_id ],
      unique: true,
      where: "vote_type = 'player'",
      name: "idx_votes_prompt_user_answer_unique"
  end

  def down
    remove_index :votes, name: "idx_votes_prompt_user_answer_unique"
    add_index :votes, [ :game_prompt_id, :user_id, :answer_id ],
      unique: true,
      where: "rank IS NOT NULL",
      name: "idx_votes_prompt_user_answer_unique"
  end
end
