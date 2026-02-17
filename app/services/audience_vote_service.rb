class AudienceVoteService
  Success = Data.define
  Failure = Data.define(:error)

  def initialize(user:, game_prompt_id:, kudos_params:, room:)
    @user = user
    @game_prompt_id = game_prompt_id
    @kudos_params = kudos_params
    @room = room
  end

  def call
    return Failure.new(error: nil) unless valid_params?
    return Failure.new(error: nil) unless valid_game_prompt?

    @clamped_kudos = @kudos_params.transform_values { |v| v.to_i.clamp(0, Vote::MAX_AUDIENCE_KUDOS) }

    return Failure.new(error: nil) unless valid_answers?
    return Failure.new(error: nil) unless valid_total?

    create_votes!
    Success.new
  rescue ActiveRecord::RecordInvalid => e
    Failure.new(error: e.message)
  end

  private

  def valid_params?
    @kudos_params.is_a?(ActionController::Parameters) || @kudos_params.is_a?(Hash)
  end

  def valid_game_prompt?
    GamePrompt.exists?(id: @game_prompt_id, game_id: @room.current_game_id)
  end

  def valid_answers?
    valid_answer_ids = Answer.where(
      game_prompt_id: @game_prompt_id,
      game_id: @room.current_game_id
    ).pluck(:id).to_set

    @clamped_kudos.keys.none? { |id| !valid_answer_ids.include?(id.to_i) }
  end

  def valid_total?
    total = @clamped_kudos.values.sum
    total > 0 && total <= Vote::MAX_AUDIENCE_KUDOS
  end

  def create_votes!
    Vote.transaction do
      if Vote.lock.where(user_id: @user.id, game_prompt_id: @game_prompt_id, vote_type: "audience").exists?
        raise ActiveRecord::RecordInvalid.new(Vote.new), "Your kudos for this round were already counted!"
      end

      @clamped_kudos.each do |answer_id, count|
        next if count <= 0
        count.times do
          Vote.create!(
            answer_id: answer_id,
            user_id: @user.id,
            game_id: @room.current_game_id,
            game_prompt_id: @game_prompt_id,
            rank: nil,
            vote_type: "audience"
          )
        end
      end
    end
  end
end
