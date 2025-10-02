class AddWonToAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :won, :boolean, null: true
  end
end
