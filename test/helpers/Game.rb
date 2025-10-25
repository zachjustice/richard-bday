class Helpers
  def self.create_player(room, name)
    User.find_or_create_by!(room: room, name: name)
  end

  def self.create_answers(room, answers)
    room.reload
    g = room.current_game
    gp = g.current_game_prompt

    User.where(room: room).each do |u|
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

  def self.create_votes(room, num_votes, tie = false)
    room.reload
    g = room.current_game
    gp = g.current_game_prompt
    answers = Answer.where(
      game: g,
      game_prompt: gp,
    ).to_a

    User.where(room: room).each do |u|
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
            answer: tie ? answers.pop : answer.sample
          )
          num_votes -= 1
        end
      end
    end
  end
end
