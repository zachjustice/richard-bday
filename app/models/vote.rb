class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :answer
  belongs_to :game
  belongs_to :game_prompt

  validates :rank, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Points are determined by the room's config, not hardcoded
  def points
    game.room.points_for_rank(rank)
  end

  after_commit(on: :create) { VoteSubmittedJob.perform_later(self) }
end
