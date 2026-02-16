class SelectWinnerService
  def initialize(game_prompt, room)
    @game_prompt = game_prompt
    @room = room
  end

  def call
    Answer.transaction do
      return if Answer.lock.where(game_prompt: @game_prompt, won: true).exists?

      votes = Vote.by_players.where(game_prompt_id: @game_prompt.id)
      answers = Answer.where(game_prompt_id: @game_prompt.id)

      points_by_answer = Hash.new(0)
      votes.each { |v| points_by_answer[v.answer_id] += v.points }

      max_points = points_by_answer.values.max || 0
      candidates = answers.select { |a| points_by_answer[a.id] == max_points }

      if candidates.any?
        winner = candidates.sample
        winner.update!(won: true)
        AnswerSmoothingJob.perform_later(winner) if @room.smooth_answers?
      else
        # No votes at all -- create default answer
        Answer.create!(
          game: @game_prompt.game,
          game_prompt: @game_prompt,
          user: User.creator.find_by(room: @room),
          text: Answer::DEFAULT_ANSWER,
          won: true
        )
      end
    end
  end
end
