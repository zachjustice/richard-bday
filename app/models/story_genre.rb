class StoryGenre < ApplicationRecord
  belongs_to :story
  belongs_to :genre

  validates :genre_id, uniqueness: { scope: :story_id }
end
