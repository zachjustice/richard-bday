class AddDefaultTextAndPublishedColumnToStories < ActiveRecord::Migration[8.0]
  def change
    change_column :stories, :text, :string, default: "Your story goes here..."
    change_column :stories, :original_text, :string, default: "The original story goes here..."
    add_column :stories, :published, :boolean, null: false, default: false
  end
end
