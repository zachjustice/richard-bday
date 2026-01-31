class UpdateVotesUniqueConstraints < ActiveRecord::Migration[8.0]
  def change
    # Remove old constraints that prevent multiple votes per user per prompt
    remove_index :votes, [ :game_id, :user_id, :answer_id ], if_exists: true
    remove_index :votes, [ :user_id, :answer_id ], if_exists: true

    # New constraints:
    # - User can only assign each rank once per prompt (only when rank is not null)
    add_index :votes, [ :game_prompt_id, :user_id, :rank ],
              unique: true,
              where: "rank IS NOT NULL",
              name: 'idx_votes_prompt_user_rank_unique'

    # - User can only vote for each answer once per prompt
    add_index :votes, [ :game_prompt_id, :user_id, :answer_id ],
              unique: true,
              name: 'idx_votes_prompt_user_answer_unique'
  end
end
