class AddTitleToStories < ActiveRecord::Migration[8.0]
  def change
    add_column :stories, :title, :text, null: false
    add_index :stories, :title, unique: true
  end
end
