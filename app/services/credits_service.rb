class CreditsService
  # Comprehensive list of "naughty" words (mild + strong profanity)
  NAUGHTY_WORDS = Set.new(%w[
    ass asses asshole assholes
    bastard bastards bitch bitches bitchy
    bollocks bugger bullshit
    cock cocks crap crappy cunt cunts
    cum cums cummies cumming cummed
    damn damned dammit dick dicks dickhead douche douchebag
    fuck fucked fucker fuckers fucking fucks
    goddamn goddam
    hell hells hellish
    jackass jerk jerkoff
    piss pissed pissing prick pricks
    pussy pussies poo poos poopoo poopoos poop poops
    shit shits shitty shithead
    slut sluts slutty
    twat whore whorish
  ]).freeze

  # Basic English word list for spell checking (loaded lazily)
  COMMON_WORDS_FILE = Rails.root.join("config", "common_words.txt")

  def initialize(game)
    @game = game
    @room = game.room
    @answers = Answer.where(game_id: game.id).includes(:user, :votes)
    @votes = Vote.where(game_id: game.id).includes(:user, :answer)
    @game_prompts = GamePrompt.where(game_id: game.id).order(:order)

    # Build user lookup from preloaded associations to avoid N+1 queries
    @users_by_id = {}
    @answers.each { |a| @users_by_id[a.user_id] = a.user }
    @votes.each { |v| @users_by_id[v.user_id] = v.user }
  end

  def call
    {
      podium: calculate_podium,
      most_swear_words: most_swear_words,
      most_characters: most_characters_written,
      best_efficiency: best_efficiency,
      most_spelling_mistakes: most_spelling_mistakes,
      slowest_player: slowest_player
    }
  end

  private

  def calculate_podium
    # Sum points from votes received on each user's answers
    user_points = Hash.new(0)

    @votes.each do |vote|
      answer_author_id = vote.answer.user_id
      user_points[answer_author_id] += vote.points
    end

    # Sort by points descending and take top 3
    top_users = user_points.sort_by { |_, points| -points }.first(3)

    top_users.map do |user_id, points|
      { user: @users_by_id[user_id], points: points }
    end
  end

  def most_swear_words
    user_swear_counts = Hash.new(0)

    @answers.each do |answer|
      count = count_naughty_words(answer.text)
      user_swear_counts[answer.user_id] += count
    end

    return nil if user_swear_counts.empty? || user_swear_counts.values.max == 0

    winner_id, count = user_swear_counts.max_by { |_, c| c }
    { user: @users_by_id[winner_id], count: count }
  end

  def most_characters_written
    user_char_counts = Hash.new(0)

    @answers.each do |answer|
      user_char_counts[answer.user_id] += answer.text.length
    end

    return nil if user_char_counts.empty?

    winner_id, count = user_char_counts.max_by { |_, c| c }
    { user: @users_by_id[winner_id], count: count }
  end

  def best_efficiency
    # Points per character - who got the most points with the least writing
    user_stats = Hash.new { |h, k| h[k] = { points: 0, characters: 0 } }

    @answers.each do |answer|
      user_stats[answer.user_id][:characters] += answer.text.length
      user_stats[answer.user_id][:points] += answer.votes.sum(&:points)
    end

    return nil if user_stats.empty?

    # Calculate efficiency (points per character), avoid division by zero
    efficiencies = user_stats.map do |user_id, stats|
      ratio = stats[:characters] > 0 ? stats[:points].to_f / stats[:characters] : 0
      [ user_id, ratio, stats[:points], stats[:characters] ]
    end

    # Only include users who actually got points
    efficiencies = efficiencies.select { |_, _, points, _| points > 0 }
    return nil if efficiencies.empty?

    winner = efficiencies.max_by { |_, ratio, _, _| ratio }
    {
      user: @users_by_id[winner[0]],
      ratio: winner[1].round(2),
      points: winner[2],
      characters: winner[3]
    }
  end

  def most_spelling_mistakes
    user_mistake_counts = Hash.new(0)

    @answers.each do |answer|
      count = count_spelling_mistakes(answer.text)
      user_mistake_counts[answer.user_id] += count
    end

    return nil if user_mistake_counts.empty? || user_mistake_counts.values.max == 0

    winner_id, count = user_mistake_counts.max_by { |_, c| c }
    { user: @users_by_id[winner_id], count: count }
  end

  def slowest_player
    user_lateness_scores = calculate_lateness_scores

    return nil if user_lateness_scores.empty?

    winner_id, score = user_lateness_scores.max_by { |_, s| s[:avg_percentile] }
    {
      user: @users_by_id[winner_id],
      avg_percentile: (score[:avg_percentile] * 100).round(0)
    }
  end

  def calculate_lateness_scores
    user_percentiles = Hash.new { |h, k| h[k] = [] }

    @game_prompts.each do |game_prompt|
      # Get answers for this prompt sorted by submission time
      prompt_answers = @answers.select { |a| a.game_prompt_id == game_prompt.id }
                               .sort_by(&:created_at)

      next if prompt_answers.empty?

      # Calculate percentile position for each user (0 = first, 1 = last)
      total = prompt_answers.size
      prompt_answers.each_with_index do |answer, index|
        percentile = total > 1 ? index.to_f / (total - 1) : 0.5
        user_percentiles[answer.user_id] << percentile
      end

      # Same for votes
      prompt_votes = @votes.select { |v| v.game_prompt_id == game_prompt.id }
                           .sort_by(&:created_at)

      next if prompt_votes.empty?

      total_votes = prompt_votes.size
      prompt_votes.each_with_index do |vote, index|
        percentile = total_votes > 1 ? index.to_f / (total_votes - 1) : 0.5
        user_percentiles[vote.user_id] << percentile
      end
    end

    # Calculate average percentile per user
    user_percentiles.transform_values do |percentiles|
      avg = percentiles.empty? ? 0 : percentiles.sum / percentiles.size
      { avg_percentile: avg, count: percentiles.size }
    end
  end

  def count_naughty_words(text)
    words = text.downcase.scan(/[a-z]+/)
    words.count { |word| NAUGHTY_WORDS.include?(word) }
  end

  def count_spelling_mistakes(text)
    words = text.scan(/[a-zA-Z]+/)
    # Skip very short words (1-2 chars) and words that look like abbreviations
    words = words.select { |w| w.length > 2 && w != w.upcase }

    words.count { |word| !valid_word?(word.downcase) }
  end

  def valid_word?(word)
    common_words.include?(word)
  end

  def common_words
    self.class.common_words
  end

  def self.common_words
    @common_words ||= load_common_words
  end

  def self.load_common_words
    if File.exist?(COMMON_WORDS_FILE)
      Set.new(File.readlines(COMMON_WORDS_FILE).map(&:strip).map(&:downcase))
    else
      Rails.logger.warn("[CreditsService] Common words file not found at #{COMMON_WORDS_FILE}")
      Set.new
    end
  end
end
