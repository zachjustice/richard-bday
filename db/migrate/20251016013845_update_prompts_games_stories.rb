class UpdatePromptsGamesStories < ActiveRecord::Migration[8.0]
  def change
    # Game.game_prompt for current game prompt
    add_reference :games, :current_game_prompt, null: true, foreign_key: { to_table: :game_prompts }
    # GamePrompt.order for which game prompt comes next.
    add_column :game_prompts, :order, :integer, null: false
    # Ensure combinations of game, prompt, blank and order are unique
    add_index :game_prompts, [ :game_id, :prompt_id, :blank_id, :order ], unique: true, name: 'index_game_prompts_on_game_prompt_blank_order'

    # Room.game for current game
    add_reference :rooms, :current_game, null: true, foreign_key: { to_table: :games }
    remove_columns :rooms, :current_prompt_index
  end
end
