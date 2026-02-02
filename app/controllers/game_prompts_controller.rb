class GamePromptsController < ApplicationController
  skip_before_action :require_authentication, only: [ :tooltip ]
  before_action :redirect_to_current_game_phase, except: [ :tooltip, :change_answer ]

  def show
    @game_prompt = GamePrompt.find_by(params.permit(:id))
    @existing_answer = Answer.find_by(
      game_prompt_id: @game_prompt.id,
      user_id: @current_user.id,
      game_id: @current_room.current_game_id
    )
  end

  def waiting
    @game_prompt = GamePrompt.find_by(params.permit(:id))

    # All answers have been collected, time to vote
    if @current_room.status == RoomStatus::Voting
      redirect_to controller: "game_prompts", action: "voting", id: params[:id]
    end
  end

  def change_answer
    @current_user.update!(status: UserStatus::Answering)

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{@current_room.id}:answers",
      target: "user_list_user_#{@current_user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: @current_user, completed: false, color: "blue" }
    )

    redirect_to controller: "game_prompts", action: "show", id: params[:id]
  end

  def voting
    exists = Vote.exists?(
      user_id: @current_user.id,
      game_prompt_id: params[:id]
    )

    # All answers have been collected, time to vote
    if exists
      Turbo::StreamsChannel.broadcast_replace_to(
        "rooms:#{@current_room.id}:answers",
        target: "user_list_user_#{@current_user.id}",
        partial: "rooms/partials/user_with_status_item",
        locals: { user: @current_user, completed: false, color: "blue" }
      )
    end

    @current_user.update!(status: UserStatus::Voting)
    @game_prompt = GamePrompt.find_by(params.permit(:id))
    @answers = Answer.where(game_id: @current_room.current_game_id, game_prompt_id: params[:id]).reject do |ans|
      ans.user_id == @current_user.id
    end
  end

  def results
    @status = @current_room.status
  end

  def tooltip
    @game_prompt = GamePrompt.find(params[:id])
    @answers = Answer.where(game_prompt_id: @game_prompt.id)
    @votes = Vote.where(game_prompt_id: @game_prompt.id)

    @votes_by_answer = @votes.group_by(&:answer_id)

    render partial: "game_prompts/tooltip_content",
          locals: {
            game_prompt: @game_prompt,
            answers: @answers,
            votes_by_answer: @votes_by_answer
          },
          layout: false
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
      if controller != "game_prompts" || id != current_game_prompt_id || ![ "show", "waiting" ].include?(action)
        redirect_to controller: "game_prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Voting
      if controller != "game_prompts" || id != current_game_prompt_id || ![ "voting", "results" ].include?(action)
        redirect_to controller: "game_prompts", action: "voting", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Results
      if controller != "game_prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "game_prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::FinalResults
      if controller != "game_prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "game_prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    else
      redirect_to controller: "rooms", action: "show"
    end
  end
end
