class Story < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :original_text, presence: true, uniqueness: true
  validates :text, presence: true, uniqueness: true
  has_one :game
end
