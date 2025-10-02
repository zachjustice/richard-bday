class AddPromptRefToVote < ActiveRecord::Migration[8.0]
  def change
    add_reference :votes, :prompt, null: false, foreign_key: true
  end
end
