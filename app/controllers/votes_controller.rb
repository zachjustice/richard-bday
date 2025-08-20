class VotesController < ApplicationController
  def create
    vote = Vote.new(
      answer_id: params[:answer_id],
      prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )
    successful = vote.save
    users_in_room = User.where(room_id: vote.room_id).count
    submitted_votes = Vote.where(prompt_id: vote.prompt_id, room_id: vote.room_id).count
    redirect_to_results = submitted_votes >= users_in_room

    if successful || redirect_to_results
      redirect_to controller: "prompts", action: "results", id: vote.prompt_id
    else
      redirect_to controller: "prompts", id: vote.prompt_id
    end
  end
end
