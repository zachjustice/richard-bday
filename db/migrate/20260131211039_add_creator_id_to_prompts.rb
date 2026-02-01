class AddCreatorIdToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_reference :prompts, :creator, null: true, foreign_key: { to_table: :editors }
  end
end
