class Blank < ApplicationRecord
  belongs_to :story

  validates :story_id, presence: true
  validates :tags, presence: true
end
