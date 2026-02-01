class AddAuthorIdToStories < ActiveRecord::Migration[8.0]
  def change
    add_reference :stories, :author, null: true, foreign_key: { to_table: :editors }
  end
end
