class PromptsController < ApplicationController
  before_action :redirect_to_current_game_phase

  def show
    exists = Answer.exists?(
      game_prompt_id: params[:id],
      user_id: @current_user.id,
      game: @current_room.current_game
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
  end

  private

  def redirect_to_current_game_phase
    controller = params[:controller]
    action = params[:action]
    id = params[:id].to_i
    current_game_prompt_id = @current_room.current_game&.current_game_prompt&.id
    case @current_room.status
    when RoomStatus::WaitingRoom
      if controller != "rooms" || id != @current_room.id || [ "show", "waiting_for_new_game" ].include?(action)
        redirect_to controller: "rooms", action: "waiting_for_new_game", id: @current_room.id
      end
    when RoomStatus::Answering
      if controller != "prompts" || id != current_game_prompt_id || ![ "show", "waiting" ].include?(action)
        redirect_to controller: "prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Voting
      if controller != "prompts" || id != current_game_prompt_id || ![ "voting", "results" ].include?(action)
        redirect_to controller: "prompts", action: "voting", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Results
      if controller != "prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::FinalResults
      if controller != "prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    else
      redirect_to controller: "rooms", action: "show"
    end
  end
end
