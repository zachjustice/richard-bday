class AddIndexToStoriesPublished < ActiveRecord::Migration[8.0]
  def change
    add_index :stories, :published
  end
end
