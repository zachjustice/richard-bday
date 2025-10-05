class CreateBlanksOld < ActiveRecord::Migration[8.0]
  def change
    create_table :blanks do |t|
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
