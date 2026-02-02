class VotesController < ApplicationController
  def create
    if @current_room.ranked_voting?
      create_ranked_votes
    else
      create_single_vote
    end
  end

  private

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
      redirect_to controller: "game_prompts", action: "results", id: params[:game_prompt_id]
    else
      flash[:alert] = error.full_messages.join(" ")
      redirect_to controller: "game_prompts", action: "show", id: params[:game_prompt_id]
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
          redirect_to controller: "game_prompts", action: "results", id: game_prompt_id
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

      redirect_to controller: "game_prompts", action: "results", id: game_prompt_id
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = e.message
      redirect_to controller: "game_prompts", action: "voting", id: game_prompt_id
    end
  end
end
