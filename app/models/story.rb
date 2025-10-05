class Story < ApplicationRecord
  validates :original_text, presence: true
  validates :text, presence: true
  has_one :game
end
