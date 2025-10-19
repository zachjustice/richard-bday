class Room < ApplicationRecord
  validates :code, presence: true
  # Technically, the game "belongs" to a "room"
  # but `belongs_to` really means the FK column is on the _this_ model.
  # which is the case- so use belongs_to instead of has_one
  belongs_to :current_game, class_name: "Game", optional: true
end
