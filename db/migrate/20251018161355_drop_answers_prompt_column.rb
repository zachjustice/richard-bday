class DropAnswersPromptColumn < ActiveRecord::Migration[8.0]
  def change
    if foreign_key_exists?(:answers, :prompts)
      remove_foreign_key :answers, :prompts
    end

    remove_column :answers, :prompt_id

    if index_exists?(:answers, [ :prompt_id, :room_id, :user_id ], name: "index_answers_on_prompt_id_and_room_id_and_user_id")
      remove_index :answers, name: "index_answers_on_prompt_id_and_room_id_and_user_id"
    end

    if index_exists?(:answer, :prompt_id, name: "index_answers_on_prompt_id")
      remove_index :answers, name: "index_answers_on_prompt_id"
    end

    if !column_exists?(:answers, :game_prompt_id)
      add_reference :answers, :game_prompt, null: false, foreign_key: { to_table: :game_prompts }
      add_index :answers, [ :game_prompt_id, :room_id, :user_id ], unique: true, name: 'index_game_prompts_on_game_prompt_id_and_room_id_and_user_id'
    end

    if foreign_key_exists?(:votes, :prompts)
      remove_foreign_key :votes, :prompts
    end

    remove_column :votes, :prompt_id

    if index_exists?(:votes, [ :prompt_id, :room_id, :user_id ], name: "index_votes_on_prompt_id_and_room_id_and_user_id")
      remove_index :votes, name: "index_votes_on_prompt_id_and_room_id_and_user_id"
    end

    if !index_exists?(:votes, [ :room_id, :user_id, :answer_id ], name: 'index_votes_on_room_id_and_user_id_and_answer_id')
      add_index :votes, [ :room_id, :user_id, :answer_id ], unique: true, name: 'index_votes_on_room_id_and_user_id_and_answer_id'
    end
  end
end
