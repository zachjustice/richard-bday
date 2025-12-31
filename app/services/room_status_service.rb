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
    when RoomStatus::Answering, RoomStatus::Voting, RoomStatus::Results
      answering_voting_results_data
    when RoomStatus::FinalResults
      final_results_data
    else
      {}
    end
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
      users_with_vote: votes.map { |v| v.user.name }
    }

    if @room.status == RoomStatus::Results
      data.merge!(results_specific_data(answers, votes))
    end

    data
  end

  def results_specific_data(answers, votes)
    votes_by_answer = {}
    most_votes = -1
    winners = []
    answers_by_id = answers.index_by(&:id)

    votes.each do |vote|
      votes_by_answer[vote.answer_id] ||= []
      votes_by_answer[vote.answer_id].push(vote)

      if votes_by_answer[vote.answer_id].size > most_votes
        most_votes = votes_by_answer[vote.answer_id].size
        winners = [ answers_by_id[vote.answer_id] ]
      elsif votes_by_answer[vote.answer_id].size == most_votes
        winners.push(answers_by_id[vote.answer_id])
      end
    end

    winner = Answer.where(
      game_prompt: @room.current_game.current_game_prompt,
      won: true
    ).first

    if winner.nil? && winners.any?
      winner = winners.sample
      winner.update!(won: true)
    else
      # No one voted. Set the answer to "poop"
      Answer.new(
        game: @room.current_game,
        game_prompt: @room.current_game.current_game_prompt,
        user: User.creator.find_by(room: @room),
        text: Answer::DEFAULT_ANSWER
      )
    end

    answers_sorted_by_votes = answers.sort do |a, b|
      (votes_by_answer[b.id]&.size || 0) <=> (votes_by_answer[a.id]&.size || 0)
    end

    {
      votes_by_answer: votes_by_answer,
      winners: winners,
      winner: winner,
      answers_sorted_by_votes: answers_sorted_by_votes
    }
  end

  def final_results_data
    story_text = @room.current_game.story.text
    winning_answers = Answer.where(game_id: @room.current_game, won: true)
    blank_id_to_answer_text = winning_answers.reduce({}) do |result, ans|
      result["{#{ans.game_prompt.blank.id}}"] = [ ans.text, ans.game_prompt.id ]
      result
    end

    replacement_regex = /\{\d+\}/
    complete_story = story_text.gsub(replacement_regex, blank_id_to_answer_text)

    validate_story(complete_story, blank_id_to_answer_text, story_text, replacement_regex)

    {
      story_text: story_text,
      blank_id_to_answer_text: blank_id_to_answer_text
    }
  end

  def validate_story(complete_story, blank_id_to_answer_text, story_text, replacement_regex)
    includes_leftover_regex = complete_story.match?(replacement_regex)
    missing_answers = blank_id_to_answer_text.values.reject { |ans| complete_story.include?(ans.first) }

    if includes_leftover_regex || !missing_answers.empty?
      error_part1 = includes_leftover_regex ? "[LEFTOVER_REGEX]" : ""
      error_part2 = !missing_answers.empty? ? "[MISSING_ANSWERS]" : ""
      Rails.logger.error(
        "[RoomStatusService#validate_story] Generated invalid story! #{error_part1}#{error_part2} " \
        "missing_answers: `#{missing_answers.to_json}`, StoryId: #{@room.current_game.story.id}, " \
        "story_text: `#{story_text}`, complete_story: `#{complete_story}`"
      )
    end
  end
end
