class Genre < ApplicationRecord
  has_many :story_genres, dependent: :destroy
  has_many :stories, through: :story_genres

  validates :name, presence: true, uniqueness: true
end
