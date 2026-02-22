class Game < ApplicationRecord
  validates :story_id, presence: true
  validates :room_id, presence: true

  belongs_to :story
  belongs_to :room

  # Technically, the game_prompt "belongs" to a "game"
  # but `belongs_to` really means the FK column is on the _this_ model.
  # which is the case- so use belongs_to instead of has_one
  belongs_to :current_game_prompt, class_name: "GamePrompt", optional: true

  # Returns { winner_user_id:, audience_favorite_user_id: } for the most recent
  # round that has a winner. Used to decorate roaming avatars with crown/party hat.
  def last_round_accolades
    last_winner = Answer.joins(:game_prompt)
      .where(game_prompts: { game_id: id }, won: true)
      .order(Arel.sql('"game_prompts"."order" DESC')).first

    result = { winner_user_id: last_winner&.user_id, audience_favorite_user_id: nil }

    if last_winner
      star_counts = Vote.by_audience
        .where(game_prompt_id: last_winner.game_prompt_id)
        .group(:answer_id).count

      if star_counts.any?
        top_answer_id = star_counts.max_by { |_, c| c }.first
        result[:audience_favorite_user_id] = Answer.find_by(id: top_answer_id)&.user_id
      end
    end

    result
  end

  # Returns { user_id => "podium_1st naughty" } with space-separated accolade tags
  # per user, computed from CreditsService data. Used for credits-phase avatar decorations.
  def credits_accolades
    data = CreditsService.new(self).call
    result = {}

    # Podium: 1st, 2nd, 3rd
    tags = %w[podium_1st podium_2nd podium_3rd]
    data[:podium].each_with_index do |entry, i|
      next unless tags[i]
      uid = entry[:user].id
      result[uid] = [ result[uid], tags[i] ].compact.join(" ")
    end

    # Superlatives
    {
      most_swear_words: "naughty",
      most_characters: "prolific",
      best_efficiency: "efficient",
      most_spelling_mistakes: "misspeller",
      slowest_player: "slowpoke",
      audience_favorite: "audience_fav"
    }.each do |key, tag|
      winner = data[key]
      next unless winner
      uid = winner[:user].id
      result[uid] = [ result[uid], tag ].compact.join(" ")
    end

    result
  end
end
