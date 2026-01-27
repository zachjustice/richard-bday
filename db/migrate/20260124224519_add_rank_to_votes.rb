class AddRankToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :rank, :integer
    add_index :votes, [:game_prompt_id, :rank]
  end
end
