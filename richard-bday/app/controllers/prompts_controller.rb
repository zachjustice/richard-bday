class PromptsController < ApplicationController
  def show
    exists = Answer.exists?(
      prompt_id: params[:id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    # User already submitted an answer for this prompt; redirect to next page
    if exists
      return redirect_to controller: "prompts", action: "waiting", id: params[:id]
    end

    @prompt = Prompt.find_by(params.permit(:id))
  end

  def waiting
    @prompt = Prompt.find_by(params.permit(:id))

    # All answers have been collected, time to vote
    if @current_room.status == RoomStatus::Voting
      redirect_to controller: "prompts", action: "voting", id: params[:id]
    end
  end

  def voting
    exists = Vote.exists?(
      prompt_id: params[:id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    # All answers have been collected, time to vote
    if exists
      return redirect_to controller: "prompts", action: "results", id: params[:id]
    end

    @prompt = Prompt.find_by(params.permit(:id))
    @answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id]).filter { |a| a.user.id != @current_user.id }
  end

  def results
    @status = @current_room.status
    current_prompt_id = GamePromptOrder.prompts()[@current_room.current_prompt_index]
    if @status != RoomStatus::Results && @status != RoomStatus::Voting
      redirect_to controller: "prompts", action: "show", id: current_prompt_id
    end
  end
end
