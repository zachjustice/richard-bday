class Game < ApplicationRecord
  validates :story_id, presence: true
  validates :room_id, presence: true

  belongs_to :story
  belongs_to :room
end
