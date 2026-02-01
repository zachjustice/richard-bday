class CreateGenresAndStoryGenres < ActiveRecord::Migration[8.0]
  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :genres, :name, unique: true

    create_table :story_genres do |t|
      t.references :story, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true
      t.timestamps
    end

    add_index :story_genres, [ :story_id, :genre_id ], unique: true
  end
end
