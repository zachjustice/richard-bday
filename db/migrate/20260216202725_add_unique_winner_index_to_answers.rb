class AddUniqueWinnerIndexToAnswers < ActiveRecord::Migration[8.0]
  def up
    # Clean up any existing duplicate winners before adding the constraint
    execute <<~SQL
      UPDATE answers SET won = 0
      WHERE won = 1
        AND id NOT IN (
          SELECT MIN(id)
          FROM answers
          WHERE won = 1
          GROUP BY game_prompt_id
        )
    SQL

    add_index :answers, :game_prompt_id, unique: true, where: "won = 1", name: "index_answers_on_game_prompt_id_unique_winner"
  end

  def down
    remove_index :answers, name: "index_answers_on_game_prompt_id_unique_winner"
  end
end
