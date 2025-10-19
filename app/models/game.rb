class Game < ApplicationRecord
  validates :story_id, presence: true
  validates :room_id, presence: true

  belongs_to :story
  belongs_to :room

  # Technically, the game_prompt "belongs" to a "game"
  # but `belongs_to` really means the FK column is on the _this_ model.
  # which is the case- so use belongs_to instead of has_one
  belongs_to :current_game_prompt, class_name: "GamePrompt", optional: true
end
