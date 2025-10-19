class ReplaceRoomColumnsWithGameColumn < ActiveRecord::Migration[8.0]
  def change
    remove_reference :answers, :rooms
    remove_column :answers, :room_id
    if index_exists? :answers, [ :room_id ], name: "index_answers_on_room_id"
      remove_index :answers, name: "index_answers_on_room_id"
    end
    if index_exists? :answers, [ :game_prompt_id, :room_id, :user_id ], name: "index_game_prompts_on_game_prompt_id_and_room_id_and_user_id"
      remove_index :answers, name: "index_game_prompts_on_game_prompt_id_and_room_id_and_user_id"
    end

    remove_reference :votes, :rooms
    remove_column :votes, :room_id
    if index_exists? :votes, [ :room_id ], name: "index_votes_on_room_id"
      remove_index :votes, name: "index_votes_on_room_id"
    end
    if index_exists? :votes, [ :room_id, :user_id, :answer_id ], name: "index_votes_on_room_id_and_user_id_and_answer_id"
      remove_index :votes, name: "index_votes_on_room_id_and_user_id_and_answer_id"
    end

    add_reference :answers, :game, null: false, foreign_key: true
    add_reference :votes, :game, null: false, foreign_key: true
    add_index :votes, [ :game_id, :user_id, :answer_id ], name: "index_votes_on_game_id_and_user_id_and_answer_id", unique: true
    add_index :answers, [ :game_prompt_id, :game_id, :user_id ], name: "index_answers_on_game_prompt_id_and_game_id_and_user_id", unique: true
  end
end
