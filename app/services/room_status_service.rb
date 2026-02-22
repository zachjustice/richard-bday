class RoomStatusService
  # TODO: replace the service with query helpers in each view.
  # I think that's a better pattern. Place the data as close as possible to the view.
  # For example, each partial and view would do something like this at the top of the page:
  # <% x, y, z = Queries.call(page: :my_current_page) %>
  def initialize(room)
    if room.is_a?(Integer)
      @room = Room.find(room)
    elsif room.is_a?(Room)
      @room = room
    else
      raise "Invalid parameter. 'room': #{room}."
    end
  end

  def call
    {
      room: @room,
      current_room: @room,
      users: fetch_users,
      status: @room.status,
      total_game_prompts: GamePrompt.where(game: @room.current_game).count
    }.merge(status_specific_data)
  end

  private

  # Sometimes the the creator is including the player list. Do a double check anyways.
  def fetch_users
    User.players.where(room_id: @room.id).reject { |u| u.name.starts_with?("Creator-") }
  end

  def status_specific_data
    case @room.status
    when RoomStatus::StorySelection
      story_selection_data
    when RoomStatus::Answering, RoomStatus::Voting, RoomStatus::Results
      answering_voting_results_data
    when RoomStatus::FinalResults
      final_results_data
    when RoomStatus::Credits
      credits_data
    else
      {}
    end
  end

  def story_selection_data
    { stories: Story.where(published: true).includes(:genres, :blanks, :author).order(:title) }
  end

  def answering_voting_results_data
    game_prompt = @room.current_game.current_game_prompt
    answers = Answer.where(game_prompt_id: game_prompt.id)
    votes = Vote.where(game_prompt_id: game_prompt.id)

    data = {
      game_prompt: game_prompt,
      answers: answers,
      users_with_submitted_answers: answers.map { |a| a.user.name },
      votes: votes,
      users_with_vote: votes.by_players.map { |v| v.user.name }
    }

    if @room.status == RoomStatus::Results
      data.merge!(results_specific_data(answers, votes))
    end

    data
  end

  def results_specific_data(answers, votes)
    # Separate audience votes from player votes
    player_votes = votes.by_players
    audience_votes = votes.by_audience

    # Unified points-based calculation for player votes only
    points_by_answer = Hash.new(0)
    votes_by_answer = Hash.new { |h, k| h[k] = [] }

    player_votes.each do |vote|
      points_by_answer[vote.answer_id] += vote.points
      votes_by_answer[vote.answer_id] << vote
    end

    max_points = points_by_answer.values.max || 0
    winners = answers.select { |a| points_by_answer[a.id] == max_points }

    # Winner should already be selected by SelectWinnerService
    winner = Answer.find_by(game_prompt: @room.current_game.current_game_prompt, won: true)

    answers_sorted_by_points = answers.sort_by { |a| -points_by_answer[a.id] }
    # Pin the winning answer to first position
    if winner && answers_sorted_by_points.delete(winner)
      answers_sorted_by_points.unshift(winner)
    end

    result = {
      votes_by_answer: votes_by_answer,
      points_by_answer: points_by_answer,
      winners: winners,
      winner: winner,
      answers_sorted_by_votes: answers_sorted_by_points,
      ranked_voting: @room.ranked_voting?
    }

    # Audience favorite calculation (only when audience voted)
    if audience_votes.any?
      audience_star_counts = Hash.new(0)
      audience_votes.each { |v| audience_star_counts[v.answer_id] += 1 }
      max_audience_stars = audience_star_counts.values.max
      audience_favorite = answers.detect { |a| audience_star_counts[a.id] == max_audience_stars }
      result[:audience_star_counts] = audience_star_counts
      result[:audience_favorite] = audience_favorite
    end

    result
  end

  def final_results_data
    FinalStoryService.new(@room.current_game).call
  end

  def credits_data
    return {} unless @room.current_game

    CreditsService.new(@room.current_game).call
  end
end
