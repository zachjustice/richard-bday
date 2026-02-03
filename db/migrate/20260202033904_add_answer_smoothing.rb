class AddAnswerSmoothing < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :smooth_answers, :boolean, default: false, null: false
    add_column :answers, :smoothed_text, :string
  end
end
