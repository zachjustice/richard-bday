class Helpers
  def initialize(room_id)
    @room_id = room_id
  end

  def create_user(name)
    User.find_or_create_by!(room_id: @room_id, name: name)
  end

  def create_users(names)
    names.each do |name|
      User.find_or_create_by!(room_id: @room_id, name: name)
    end
  end

  def create_answers(answers)
    room = Room.find(@room_id)
    g = room.current_game
    gp = g.current_game_prompt

    User.players.where(room: room).each do |u|
      if answers.size
        missing = Answer.where(
          game: g,
          game_prompt: gp,
          user: u
        ).count == 0
        if missing
          Answer.find_or_create_by!(
            game: g,
            game_prompt: gp,
            user: u,
            text: answers.pop
          )
        end
      end
    end
  end

  def create_votes(num_votes, tie = false)
    room = Room.find(@room_id)
    g = room.current_game
    gp = g.current_game_prompt
    answers = Answer.where(
      game: g,
      game_prompt: gp,
    ).to_a

    User.players.where(room: room).each do |u|
      if num_votes > 0
        missing = Vote.where(
          game: g,
          game_prompt: gp,
          user: u,
        ).count == 0
        if missing
          Vote.find_or_create_by!(
            game: g,
            game_prompt: gp,
            user: u,
            answer: tie ? answers.pop : answers.sample
          )
          num_votes -= 1
        end
      end
    end
  end

  def move_to_answering(skip_timer = false)
    room = Room.find(@room_id)
    current_game_prompt_order = room.current_game.current_game_prompt.order
    next_game_prompt_id = GamePrompt.find_by(game_id: room.current_game_id, order: current_game_prompt_order + 1)&.id

    ActionCable.server.broadcast(
      "rooms:#{room.id}",
      Events.create_next_prompt_event(next_game_prompt_id)
    )
    room.update!(status: RoomStatus::Answering)
    next_game_phase_time = Time.now + room.time_to_answer_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS
    room.current_game.update!(current_game_prompt_id: next_game_prompt_id, next_game_phase_time: next_game_phase_time)

    # Start timer for answers
    if skip_timer
      AnsweringTimesUpJob.set(wait_until: next_game_phase_time).perform_later(room, next_game_prompt_id)
    end
  end
end
