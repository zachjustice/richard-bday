class PromptsController < ApplicationController
  def show
    exists = Answer.exists?(
      game_prompt_id: params[:id],
      user_id: @current_user.id,
      game_id: @current_room.current_game_id
    )

    # User already submitted an answer for this prompt; redirect to next page
    if exists
      return redirect_to controller: "prompts", action: "waiting", id: params[:id]
    end

    @game_prompt = GamePrompt.find_by(params.permit(:id))
  end

  def waiting
    @game_prompt = GamePrompt.find_by(params.permit(:id))

    # All answers have been collected, time to vote
    if @current_room.status == RoomStatus::Voting
      redirect_to controller: "prompts", action: "voting", id: params[:id]
    end
  end

  def voting
    exists = Vote.exists?(
      user_id: @current_user.id,
      game_prompt_id: params[:id]
    )

    # All answers have been collected, time to vote
    if exists
      return redirect_to controller: "prompts", action: "results", id: params[:id]
    end

    @game_prompt = GamePrompt.find_by(params.permit(:id))
    @answers = Answer.where(game_id: @current_room.current_game_id, game_prompt_id: params[:id]).reject do |ans|
      ans.user_id == @current_user.id
    end
  end

  def results
    @status = @current_room.status
    current_game_prompt_id = @current_room&.current_game&.current_game_prompt&.id
    if @status == RoomStatus::Answering
      redirect_to controller: "prompts", action: "show", id: current_game_prompt_id
    end
  end
end
