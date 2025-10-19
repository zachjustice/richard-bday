class AnswersController < ApplicationController
  def create
    exists = Answer.exists?(
      game_prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      game_id: @current_room.current_game_id
    )

    # If the user has already submitted an answer for the prompt and room, then skip saving a new answer
    # --> Direct the user to the prompt/:id/voting or prompt/:id/waiting page appropriately
    successful = false
    if !exists
      ans = Answer.new(
        text: params[:text],
        game_prompt_id: params[:prompt_id],
        user_id: @current_user.id,
        game_id: @current_room.current_game_id
      )
      ans.save!
    end

    users_in_room = User.where(room_id: @current_room.id).count
    submitted_answers = Answer.where(game_prompt_id: params[:prompt_id], game_id: @current_room.current_game_id).count
    redirect_to_voting = submitted_answers >= users_in_room

    # All answers have been collected, time to vote
    if redirect_to_voting
      return redirect_to controller: "prompts", action: "voting", id: params[:prompt_id]
    end

    if successful
      redirect_to controller: "prompts", action: "waiting", id: params[:prompt_id]
    else
      redirect_to controller: "prompts", action: "show", id: params[:prompt_id], alert: "Something went wrong."
    end
  end
end
