class VotesController < ApplicationController
  include GamePhaseNavigation

  def create
    if @current_user.audience?
      create_audience_votes
    elsif @current_room.ranked_voting?
      create_ranked_votes
    else
      create_single_vote
    end
  end

  private

  def create_audience_votes
    result = AudienceVoteService.new(
      user: @current_user,
      game_prompt_id: params[:game_prompt_id],
      kudos_params: params[:kudos],
      room: @current_room
    ).call

    case result
    in AudienceVoteService::Success
      turbo_nav_or_redirect_to game_prompt_results_path(params[:game_prompt_id])
    in AudienceVoteService::Failure(error:) if error
      flash[error.include?("already") ? :notice : :alert] = error
      turbo_nav_or_redirect_to path_for_current_phase(@current_room, @current_user)
    else
      turbo_nav_or_redirect_to path_for_current_phase(@current_room, @current_user)
    end
  end

  def create_single_vote
    exists = Vote.exists?(
      user_id: @current_user.id,
      game_prompt_id: params[:game_prompt_id]
    )

    # If the user has already voted for the prompt and room, then skip saving a new answer
    successful = false
    error = nil
    if !exists
      vote = Vote.new(
        answer_id: params[:answer_id],
        user_id: @current_user.id,
        game_id: @current_room.current_game_id,
        game_prompt_id: params[:game_prompt_id],
        rank: nil,
        vote_type: "player"
      )
      successful = vote.save
      error = vote.errors
    end

    users_in_room = User.players.where(room_id: @current_room.id).count
    submitted_votes_count = User.players.where(room_id: @current_room.id, status: UserStatus::Voted).count
    redirect_to_results = submitted_votes_count >= users_in_room

    if successful || exists || redirect_to_results
      turbo_nav_or_redirect_to game_prompt_results_path(params[:game_prompt_id])
    else
      flash[:alert] = error.full_messages.join(" ")
      turbo_nav_or_redirect_to game_prompt_path(params[:game_prompt_id])
    end
  end

  def create_ranked_votes
    rankings = params[:rankings] || {}
    game_prompt_id = params[:game_prompt_id]

    begin
      Vote.transaction do
        # Lock the user's existing votes to prevent race conditions from double-submit
        existing_votes = Vote.lock.where(
          user_id: @current_user.id,
          game_prompt_id: game_prompt_id
        )

        if existing_votes.exists?
          turbo_nav_or_redirect_to game_prompt_results_path(game_prompt_id)
          return
        end

        rankings.each do |rank, answer_id|
          next if answer_id.blank?

          Vote.create!(
            answer_id: answer_id,
            user_id: @current_user.id,
            game_id: @current_room.current_game_id,
            game_prompt_id: game_prompt_id,
            rank: rank.to_i,
            vote_type: "player"
          )
        end
      end

      turbo_nav_or_redirect_to game_prompt_results_path(game_prompt_id)
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = e.message
      turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
    end
  end
end
