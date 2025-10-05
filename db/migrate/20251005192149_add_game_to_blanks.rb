class AddGameToBlanks < ActiveRecord::Migration[8.0]
  def change
    add_reference :blanks, :game, null: false, foreign_key: true
  end
end
