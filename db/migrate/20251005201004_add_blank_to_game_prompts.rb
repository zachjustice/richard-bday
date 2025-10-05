class AddBlankToGamePrompts < ActiveRecord::Migration[8.0]
  def change
    add_reference :game_prompts, :blank, null: false, foreign_key: true
  end
end
