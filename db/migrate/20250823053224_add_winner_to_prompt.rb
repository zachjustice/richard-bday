class AddWonToAnswer < ActiveRecord::Migration[8.0]
  def change
    add_reference :answers, :won, default: false, null: true
  end
end
