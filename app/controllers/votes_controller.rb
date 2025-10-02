class VotesController < ApplicationController
  def create
    exists = Vote.exists?(
      prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    # If the user has already voted for the prompt and room, then skip saving a new answer
    # --> Direct the user to the appropirate page.
    successful = false
    if !exists
      vote = Vote.new(
        answer_id: params[:answer_id],
        prompt_id: params[:prompt_id],
        user_id: @current_user.id,
        room_id: @current_room.id
      )
      successful = vote.save
    end

    users_in_room = User.where(room_id: @current_room.id).count
    submitted_votes = Vote.where(prompt_id: params[:id], room_id: @current_room.id).count
    redirect_to_results = submitted_votes >= users_in_room

    if successful || exists || redirect_to_results
      redirect_to controller: "prompts", action: "results", id: params[:prompt_id]
    else
      redirect_to controller: "prompts", action: "show", id: params[:prompt_id]
    end
  end
end
