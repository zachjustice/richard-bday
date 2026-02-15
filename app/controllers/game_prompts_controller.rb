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
      turbo_nav_or_redirect_to game_prompt_voting_path(params[:id])
      return
    end

    @users = User.players.where(room_id: @current_room.id) if discord_authenticated?
  end

  def change_answer
    @current_user.update!(status: UserStatus::Answering)

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{@current_room.id}:answers",
      target: "user_list_user_#{@current_user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: @current_user, completed: false, color: "blue" }
    )

    # Update roaming avatar status badge (Discord)
    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{@current_room.id}:avatar-status",
      target: "waiting_room_user_#{@current_user.id}",
      partial: "rooms/partials/user_list_item",
      locals: { user: @current_user }
    )

    # Update "X of N done" counter
    users_in_room = User.players.where(room: @current_room).count
    answered_users = User.players.where(room: @current_room, status: UserStatus::Answered).count
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{@current_room.id}:avatar-status",
      action: :update,
      target: "players-done-count",
      html: "#{answered_users} of #{users_in_room}"
    )

    turbo_nav_or_redirect_to game_prompt_path(params[:id])
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

    if discord_authenticated? && @status == RoomStatus::Results
      service_data = RoomStatusService.new(@current_room).call
      @winner = service_data[:winner]
      @winners = service_data[:winners]
      @answers_sorted_by_votes = service_data[:answers_sorted_by_votes]
      @votes_by_answer = service_data[:votes_by_answer]
      @points_by_answer = service_data[:points_by_answer]
      @ranked_voting = service_data[:ranked_voting]
    end
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
        turbo_nav_or_redirect_to waiting_for_new_game_path(@current_room)
      end
    when RoomStatus::StorySelection, RoomStatus::Credits
      turbo_nav_or_redirect_to show_room_path
    when RoomStatus::Answering
      if controller != "game_prompts" || id != current_game_prompt_id || ![ "show", "waiting" ].include?(action)
        turbo_nav_or_redirect_to game_prompt_path(@current_room.current_game.current_game_prompt)
      end
    when RoomStatus::Voting
      if controller != "game_prompts" || id != current_game_prompt_id || ![ "voting", "results" ].include?(action)
        turbo_nav_or_redirect_to game_prompt_voting_path(@current_room.current_game.current_game_prompt)
      end
    when RoomStatus::Results
      if controller != "game_prompts" || id != current_game_prompt_id || action != "results"
        turbo_nav_or_redirect_to game_prompt_results_path(@current_room.current_game.current_game_prompt)
      end
    when RoomStatus::FinalResults
      if controller != "game_prompts" || id != current_game_prompt_id || action != "results"
        turbo_nav_or_redirect_to game_prompt_results_path(@current_room.current_game.current_game_prompt)
      end
    else
      turbo_nav_or_redirect_to show_room_path
    end
  end
end
