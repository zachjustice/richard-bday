class CreateStory < ActiveRecord::Migration[8.0]
  def change
    create_table :stories do |t|
      t.string :original_text
      t.string :text

      t.timestamps
    end
  end
end
