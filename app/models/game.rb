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

  # Returns the accolade tag string for a single user, derived from current room phase.
  # Memoized — first call builds the full map, subsequent lookups are O(1).
  def accolade_for(user)
    @accolade_map ||= build_accolade_map
    @accolade_map[user.id] || ""
  end

  # Returns { user_id => "podium_1st naughty" } with space-separated accolade tags
  # per user, computed from CreditsService data. Used for credits-phase avatar decorations.
  def credits_accolades
    data = CreditsService.new(self).call
    result = {}

    # Podium: 1st, 2nd, 3rd
    data[:podium].each_with_index do |entry, i|
      next unless AccoladeTags::PODIUM_TAGS[i]
      uid = entry[:user].id
      result[uid] = [ result[uid], AccoladeTags::PODIUM_TAGS[i] ].compact.join(" ")
    end

    # Superlatives
    {
      most_swear_words: AccoladeTags::NAUGHTY,
      most_characters: AccoladeTags::PROLIFIC,
      best_efficiency: AccoladeTags::EFFICIENT,
      most_spelling_mistakes: AccoladeTags::MISSPELLER,
      slowest_player: AccoladeTags::SLOWPOKE,
      audience_favorite: AccoladeTags::CROWD_PICK
    }.each do |key, tag|
      winner = data[key]
      next unless winner
      uid = winner[:user].id
      result[uid] = [ result[uid], tag ].compact.join(" ")
    end

    result
  end

  private

  def build_accolade_map
    # Post-game phases use credits accolades (podium + superlatives + crowd_pick).
    # FinalResults is included because Discord players can navigate to the credits
    # page via a GET link without flipping room.status to Credits.
    if [ RoomStatus::FinalResults, RoomStatus::Credits ].include?(room.status)
      credits_accolades
    else
      map = {}
      accolades = last_round_accolades
      if (winner_id = accolades[:winner_user_id])
        map[winner_id] = AccoladeTags::WINNER
      end
      if (fav_id = accolades[:audience_favorite_user_id])
        map[fav_id] = [ map[fav_id], AccoladeTags::AUDIENCE_FAVORITE ].compact.join(" ")
      end
      map
    end
  end
end
