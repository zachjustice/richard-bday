class GamePromptsController < ApplicationController
  include GamePhaseNavigation

  skip_before_action :require_authentication, only: [ :tooltip ]
  before_action :redirect_to_current_game_phase, except: [ :tooltip, :change_answer ]

  def show
    if @current_user.audience?
      turbo_nav_or_redirect_to game_prompt_waiting_path(params[:id])
      return
    end

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
    return turbo_nav_or_redirect_to show_room_path if @current_user.audience?

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
    @game_prompt = GamePrompt.find_by(params.permit(:id))
    @answers = Answer.where(game_id: @current_room.current_game_id, game_prompt_id: params[:id])

    if @current_user.audience?
      if Vote.exists?(user_id: @current_user.id, game_prompt_id: params[:id], vote_type: "audience")
        turbo_nav_or_redirect_to game_prompt_results_path(params[:id])
        return
      end
      @answers = @answers.to_a
      return
    end

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
    @answers = @answers.reject { |ans| ans.user_id == @current_user.id }
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
      @audience_favorite = service_data[:audience_favorite]
      @audience_star_counts = service_data[:audience_star_counts]
    end
  end

  def tooltip
    @game_prompt = GamePrompt.find(params[:id])
    @answers = Answer.where(game_prompt_id: @game_prompt.id)
    @votes = Vote.by_players.where(game_prompt_id: @game_prompt.id)

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

    # Audience members have unlimited time to vote, so they may still be on a
    # previous round's voting page when the game advances. We exempt them here:
    # once they submit, the votes controller navigates them to the correct phase.
    # Audience stars are non-critical, so missing a round is acceptable.
    return if @current_user.audience? && controller == "game_prompts" && action == "voting"

    case @current_room.status
    when RoomStatus::WaitingRoom
      if controller != "rooms" || id != @current_room.id || [ "show", "waiting_for_new_game" ].include?(action)
        turbo_nav_or_redirect_to waiting_for_new_game_path(@current_room)
      end
    when RoomStatus::StorySelection
      turbo_nav_or_redirect_to show_room_path
    when RoomStatus::Answering
      if @current_user.audience?
        unless controller == "game_prompts" && id == current_game_prompt_id && action == "waiting"
          turbo_nav_or_redirect_to game_prompt_waiting_path(@current_room.current_game.current_game_prompt)
        end
      elsif controller != "game_prompts" || id != current_game_prompt_id || ![ "show", "waiting" ].include?(action)
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
      turbo_nav_or_redirect_to room_story_path(@current_room)
    when RoomStatus::Credits
      turbo_nav_or_redirect_to room_game_credits_path(@current_room)
    else
      turbo_nav_or_redirect_to show_room_path
    end
  end
end
