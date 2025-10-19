class AddWonColumnToAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :won, :boolean, default: nil
  end
end
