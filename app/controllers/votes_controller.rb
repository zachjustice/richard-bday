class VotesController < ApplicationController
  def create
    exists = Vote.exists?(
      user_id: @current_user.id,
      game_prompt_id: params[:game_prompt_id]
    )

    # If the user has already voted for the prompt and room, then skip saving a new answer
    # --> Direct the user to the appropirate page.
    successful = false
    if !exists
      vote = Vote.new(
        answer_id: params[:answer_id],
        user_id: @current_user.id,
        game_id: @current_room.current_game_id,
        game_prompt_id: params[:game_prompt_id]
      )
      successful = vote.save
    end

    users_in_room = User.where(room_id: @current_room.id).count
    submitted_votes = Vote.where(game_id: @current_room.current_game_id).count
    redirect_to_results = submitted_votes >= users_in_room

    if successful || exists || redirect_to_results
      redirect_to controller: "prompts", action: "results", id: params[:game_prompt_id]
    else
      redirect_to controller: "prompts", action: "show", id: params[:game_prompt_id]
    end
  end
end
