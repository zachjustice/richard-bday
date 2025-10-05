class CreateGamePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :game_prompts do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :blank, null: false, foreign_key: true

      t.timestamps
    end
  end
end
