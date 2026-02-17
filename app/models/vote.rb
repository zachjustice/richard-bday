class Vote < ApplicationRecord
  MAX_AUDIENCE_KUDOS = 5

  belongs_to :user
  belongs_to :answer
  belongs_to :game
  belongs_to :game_prompt

  validates :rank, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :rank, absence: true, if: :audience?
  validates :vote_type, inclusion: { in: %w[player audience] }

  scope :by_players, -> { where(vote_type: "player") }
  scope :by_audience, -> { where(vote_type: "audience") }

  def audience?
    vote_type == "audience"
  end

  def player?
    vote_type == "player"
  end

  # Points are determined by the room's config, not hardcoded
  def points
    return 0 if audience?
    game.room.points_for_rank(rank)
  end

  after_commit(on: :create) { VoteSubmittedJob.perform_later(self) }
end
