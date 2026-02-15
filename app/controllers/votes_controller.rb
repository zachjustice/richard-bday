class VotesController < ApplicationController
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
    game_prompt_id = params[:game_prompt_id]
    stars = params[:stars]

    # Validate stars is a Hash (ActionController::Parameters)
    unless stars.is_a?(ActionController::Parameters) || stars.is_a?(Hash)
      turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
      return
    end

    # Validate game_prompt belongs to the current game
    unless GamePrompt.exists?(id: game_prompt_id, game_id: @current_room.current_game_id)
      turbo_nav_or_redirect_to audience_destination
      return
    end

    # Clamp individual star values and sum
    clamped_stars = stars.transform_values { |v| v.to_i.clamp(0, Vote::MAX_AUDIENCE_STARS) }

    # Validate answer_ids belong to this game_prompt
    valid_answer_ids = Answer.where(game_prompt_id: game_prompt_id, game_id: @current_room.current_game_id).pluck(:id).to_set
    if clamped_stars.keys.any? { |id| !valid_answer_ids.include?(id.to_i) }
      turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
      return
    end

    total_stars = clamped_stars.values.sum
    if total_stars > Vote::MAX_AUDIENCE_STARS || total_stars <= 0
      turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
      return
    end

    Vote.transaction do
      # Prevent duplicate audience submissions
      if Vote.lock.where(user_id: @current_user.id, game_prompt_id: game_prompt_id).exists?
        flash[:notice] = "You've already voted for this round!"
        turbo_nav_or_redirect_to audience_destination
        return
      end

      clamped_stars.each do |answer_id, count|
        next if count <= 0
        count.times do
          Vote.create!(
            answer_id: answer_id,
            user_id: @current_user.id,
            game_id: @current_room.current_game_id,
            game_prompt_id: game_prompt_id,
            rank: nil,
            vote_type: "audience"
          )
        end
      end
    end

    flash[:notice] = "Stars submitted!"
    turbo_nav_or_redirect_to audience_destination
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
  end

  def audience_destination
    current_prompt = @current_room.current_game&.current_game_prompt
    return show_room_path unless current_prompt
    case @current_room.status
    when RoomStatus::Voting
      game_prompt_voting_path(current_prompt)
    when RoomStatus::Results, RoomStatus::FinalResults
      game_prompt_results_path(current_prompt)
    when RoomStatus::Credits
      show_room_path
    when RoomStatus::Answering
      game_prompt_waiting_path(current_prompt)
    else
      show_room_path
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
