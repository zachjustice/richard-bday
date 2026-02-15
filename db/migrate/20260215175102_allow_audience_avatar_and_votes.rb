class AllowAudienceAvatarAndVotes < ActiveRecord::Migration[8.0]
  def up
    # Allow multiple audience members to share the 👁️ avatar
    remove_index :users, [ :room_id, :avatar ], unique: true
    add_index :users, [ :room_id, :avatar ], unique: true, where: "role != 'Audience'", name: "index_users_on_room_id_and_avatar"

    # Audience star votes are unranked (rank IS NULL) and multiple can target the same answer,
    # so only enforce uniqueness for ranked (player) votes
    remove_index :votes, name: "idx_votes_prompt_user_answer_unique"
    add_index :votes, [ :game_prompt_id, :user_id, :answer_id ], unique: true, where: "rank IS NOT NULL", name: "idx_votes_prompt_user_answer_unique"
  end

  def down
    remove_index :users, name: "index_users_on_room_id_and_avatar"
    add_index :users, [ :room_id, :avatar ], unique: true, name: "index_users_on_room_id_and_avatar"

    remove_index :votes, name: "idx_votes_prompt_user_answer_unique"
    add_index :votes, [ :game_prompt_id, :user_id, :answer_id ], unique: true, name: "idx_votes_prompt_user_answer_unique"
  end
end
