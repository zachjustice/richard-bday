require "faker"

class Helpers
  def initialize(room_id = nil)
    @room_id = room_id || Room.last!.id
  end

  def create_users(names_or_num = 5)
    if names_or_num.is_a? Numeric
      names = create_fake_names(names_or_num)
    else
      names = names_or_num
    end

    names.each do |name|
      User.find_or_create_by!(
        room_id: @room_id,
        name: name,
        avatar: User.available_avatars(@room_id).sample
      )
    end
  end

  def create_answers(answers_or_num = nil)
    room = Room.find(@room_id)
    g = room.current_game
    gp = g.current_game_prompt

    # Get players who haven't answered yet
    players = User.players.where(room: room).to_a
    players_without_answers = players.reject do |u|
      Answer.where(game: g, game_prompt: gp, user: u).exists?
    end

    if answers_or_num.is_a? Numeric
      answers = create_fake_answers(answers_or_num)
    elsif answers_or_num.is_a? Array
      answers = answers_or_num.dup
    else
      answers = create_fake_answers(players_without_answers.size)
    end

    # Create answers
    # Chose the smaller value- i.e. if there are fewer players or requested num of votes
    num_desired_answers = [ answers.length, players_without_answers.length ].min
    answers[0...num_desired_answers].each_with_index do |text, idx|
      Answer.create!(
        game: g,
        game_prompt: gp,
        user: players_without_answers[idx],
        text: text
      )
    end
  end

  def create_votes(num_votes = nil, tie: false)
    room = Room.find(@room_id)
    g = room.current_game
    gp = g.current_game_prompt
    answers = Answer.where(game: g, game_prompt: gp).to_a

    # Get players who haven't voted yet
    players = User.players.where(room: room).to_a
    players_without_votes = players.reject do |u|
      Vote.where(game: g, game_prompt: gp, user: u, vote_type: "player").exists?
    end

    # Create votes
    num_votes ||= players_without_votes.length
    # Chose the smaller value- i.e. if there are fewer players or requested num of votes
    [ num_votes, players_without_votes.length ].min.times do |idx|
      user = players_without_votes[idx]

      if room.ranked_voting?
        max_ranks = [ room.max_ranks, answers.size ].min
        ranked_answers = tie ? answers.first(max_ranks) : answers.sample(max_ranks)
        ranked_answers.each_with_index do |answer, rank_idx|
          Vote.create!(
            game: g,
            game_prompt: gp,
            user: user,
            answer: answer,
            rank: rank_idx + 1,
            vote_type: "player"
          )
        end
      else
        Vote.create!(
          game: g,
          game_prompt: gp,
          user: user,
          answer: tie ? answers[idx % answers.size] : answers.sample,
          vote_type: "player"
        )
      end
    end
  end

  def create_audience_members(names_or_num = 5)
    if names_or_num.is_a? Numeric
      names = create_fake_names(names_or_num)
    else
      names = names_or_num
    end

    names.each do |name|
      User.find_or_create_by!(
        room_id: @room_id,
        name: name,
        role: User::AUDIENCE
      )
    end
  end

  def create_audience_votes(num_voters = nil)
    room = Room.find(@room_id)
    g = room.current_game
    gp = g.current_game_prompt
    answers = Answer.where(game: g, game_prompt: gp).to_a
    return if answers.empty?

    audience = User.audience.where(room: room).to_a
    voters = audience.reject do |u|
      Vote.where(game: g, game_prompt: gp, user: u).exists?
    end

    voters = voters.first(num_voters) if num_voters

    voters.each do |user|
      total_stars = rand(1..Vote::MAX_AUDIENCE_KUDOS)
      total_stars.times do
        answer = answers.sample
        Vote.create!(
          game: g,
          game_prompt: gp,
          user: user,
          answer: answer,
          rank: nil,
          vote_type: "audience"
        )
      end
    end
  end

  def go(status)
    target_status = resolve_room_status_prefix(status)
    room = Room.find(@room_id)

    result = DevPhaseSimulatorService.new(room: room, target_status: target_status).call
    if result.is_a?(DevPhaseSimulatorService::Failure)
      raise "DevPhaseSimulator failed: #{result.error}"
    end

    room.reload
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{room.id}:nav-updates",
      action: :navigate,
      target: nav_target_for(room, target_status)
    )
    room
  end

  private def resolve_room_status_prefix(prefix)
    needle = prefix.to_s.downcase
    matches = RoomStatus.constants.map(&:to_s).select { |c| c.downcase.start_with?(needle) }
    if matches.empty?
      raise ArgumentError, "Unknown roomStatus prefix #{prefix.inspect}: no RoomStatus constant matches"
    end
    if matches.size > 1
      raise ArgumentError, "Ambiguous roomStatus prefix #{prefix.inspect} matches: #{matches.inspect}"
    end
    matches.first
  end

  private def nav_target_for(room, target_status)
    case target_status
    when RoomStatus::WaitingRoom
      Game.exists?(room_id: room.id) ? "/rooms/#{room.id}/waiting_for_new_game" : "/rooms/#{room.id}"
    when RoomStatus::StorySelection
      "/rooms/#{room.id}/story"
    when RoomStatus::Answering
      "/game_prompts/#{room.current_game.current_game_prompt_id}"
    when RoomStatus::Voting
      "/game_prompts/#{room.current_game.current_game_prompt_id}/voting"
    when RoomStatus::Results
      "/game_prompts/#{room.current_game.current_game_prompt_id}/results"
    when RoomStatus::FinalResults
      "/rooms/#{room.id}/story"
    when RoomStatus::Credits
      "/rooms/#{room.id}/game_credits"
    end
  end

  def move_to_answering(use_times_up_job = false)
    room = Room.find(@room_id)
    current_game_prompt_order = room.current_game.current_game_prompt.order
    next_game_prompt_id = GamePrompt.find_by(game_id: room.current_game_id, order: current_game_prompt_order + 1)&.id

    if next_game_prompt_id
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:nav-updates",
        action: :navigate,
        target: "/prompts/#{next_game_prompt_id}",
      )
      room.update!(status: RoomStatus::Answering)
      next_game_phase_time = Time.now + room.time_to_answer_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS
      room.current_game.update!(current_game_prompt_id: next_game_prompt_id, next_game_phase_time: next_game_phase_time)
    else
      room.update!(status: RoomStatus::FinalResults)
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:nav-updates",
        action: :navigate,
        target: "/prompts/#{room.current_game.current_game_prompt_id}/results",
      )
    end

    # Start timer for answers
    if use_times_up_job
      AnsweringTimesUpJob.set(wait_until: next_game_phase_time).perform_later(room, next_game_prompt_id)
    end
  end

  private def create_fake_names(num_fake_names)
    num_fake_names.times.map do
      Faker::Name.unique.name[0...15]
    end
  end

  private def create_fake_answers(num_fake_answers)
    num_fake_answers.times.map do
      Faker::Lorem.sentence(word_count: rand(5...20)).gsub(".", "")[0...150]
    end
  end
end
