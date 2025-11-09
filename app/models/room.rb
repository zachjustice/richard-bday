class Room < ApplicationRecord
  MIN_WAITING_TIME_SECONDS = 30
  MAX_WAITING_TIME_SECONDS = 20.minutes.to_i

  validates :code, presence: true
  validates :time_to_answer_seconds, numericality: {
    only_integer: true,
    greater_than_or_equal_to: MIN_WAITING_TIME_SECONDS,
    less_than_or_equal_to: MAX_WAITING_TIME_SECONDS,
    message: "must be between 30 and #{MAX_WAITING_TIME_SECONDS} seconds"
  }
  validates :time_to_vote_seconds, numericality: {
    only_integer: true,
    greater_than_or_equal_to: MIN_WAITING_TIME_SECONDS,
    less_than_or_equal_to: MAX_WAITING_TIME_SECONDS,
    message: "must be between 30 and #{MAX_WAITING_TIME_SECONDS} seconds"
  }

  # Technically, the game "belongs" to a "room"
  # but `belongs_to` really means the FK column is on the _this_ model.
  # which is the case- so use belongs_to instead of has_one
  belongs_to :current_game, class_name: "Game", optional: true
end
