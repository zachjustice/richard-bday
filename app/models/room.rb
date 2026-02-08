class Room < ApplicationRecord
  MIN_WAITING_TIME_SECONDS = 30
  MAX_WAITING_TIME_SECONDS = 20.minutes.to_i

  VOTING_STYLES = %w[vote_once ranked_top_3].freeze

  # Default configs for each voting style
  VOTING_STYLE_DEFAULTS = {
    "vote_once" => {},
    "ranked_top_3" => { "max_ranks" => 3, "points" => { "1" => 30, "2" => 20, "3" => 10 } }
  }.freeze

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
  validates :voting_style, inclusion: { in: VOTING_STYLES }

  # Technically, the game "belongs" to a "room"
  # but `belongs_to` really means the FK column is on the _this_ model.
  # which is the case- so use belongs_to instead of has_one
  belongs_to :current_game, class_name: "Game", optional: true

  def self.generate_unique_code(length: 4, max_retries: 10)
    max_retries.times do
      code = Array.new(length) { ("a".."z").to_a.sample }.join
      return code unless exists?(code: code)
    end
    raise "Failed to generate unique room code after #{max_retries} attempts"
  end

  def ranked_voting?
    voting_style == "ranked_top_3"
  end

  def vote_once?
    voting_style == "vote_once"
  end

  # Get voting config for the current voting style
  def voting_config
    VOTING_STYLE_DEFAULTS[voting_style]
  end

  def max_ranks
    voting_config["max_ranks"] || 1
  end

  def points_for_rank(rank)
    return 1 if vote_once? || rank.nil?
    voting_config.dig("points", rank.to_s) || 0
  end
end
