class GamePrompt < ApplicationRecord
  belongs_to :prompt
  belongs_to :game
  belongs_to :blank

  validates :prompt_id, presence: true
  validates :game_id, presence: true
  validates :blank_id, presence: true
end
