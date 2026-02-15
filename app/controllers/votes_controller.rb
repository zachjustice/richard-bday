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

  MAX_AUDIENCE_STARS = 5

  def create_audience_votes
    game_prompt_id = params[:game_prompt_id]
    stars = params[:stars] || {}

    # Sum only positive counts so crafted negative values can't bypass the total cap
    total_stars = stars.values.sum { |v| [ v.to_i, 0 ].max }
    if total_stars > MAX_AUDIENCE_STARS || total_stars <= 0
      turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
      return
    end

    Vote.transaction do
      # Prevent duplicate audience submissions
      if Vote.where(user_id: @current_user.id, game_prompt_id: game_prompt_id).exists?
        turbo_nav_or_redirect_to audience_destination
        return
      end

      stars.each do |answer_id, count|
        next if count.to_i <= 0
        count.to_i.times do
          Vote.create!(
            answer_id: answer_id,
            user_id: @current_user.id,
            game_id: @current_room.current_game_id,
            game_prompt_id: game_prompt_id,
            rank: nil
          )
        end
      end
    end

    turbo_nav_or_redirect_to audience_destination
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    turbo_nav_or_redirect_to game_prompt_voting_path(game_prompt_id)
  end

  def audience_destination
    current_prompt = @current_room.current_game&.current_game_prompt
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
        rank: nil
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
            rank: rank.to_i
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
