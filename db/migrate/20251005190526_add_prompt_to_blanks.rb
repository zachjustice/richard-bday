class AddPromptToBlanks < ActiveRecord::Migration[8.0]
  def change
    add_reference :blanks, :prompt, null: false, foreign_key: true
  end
end
