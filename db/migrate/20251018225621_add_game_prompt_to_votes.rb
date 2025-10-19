class AddGamePromptToVotes < ActiveRecord::Migration[8.0]
  def change
    add_reference :votes, :game_prompt, null: false, foreign_key: true
  end
end
