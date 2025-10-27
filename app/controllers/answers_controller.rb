class AnswersController < ApplicationController
  # TODO: clean up this logic.
  # I think that it should:
  # - Create answer should be idempotent (as it is today)
  # - But if it fails, display the error message in the flash[:notice] instead of alert
  # - I'm confusing by the routing.
  def create
    exists = Answer.exists?(
      game_prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      game_id: @current_room.current_game_id
    )

    # If the user has already submitted an answer for the prompt and room, then skip saving a new answer
    # --> Direct the user to the prompt/:id/voting or prompt/:id/waiting page appropriately
    if !exists
      ans = Answer.new(
        text: params[:text],
        game_prompt_id: params[:prompt_id],
        user_id: @current_user.id,
        game_id: @current_room.current_game_id
      )
      if !ans.save
        flash[:notice] = ans.errors.full_messages.to_json
        return redirect_to controller: "prompts", action: "show", id: params[:prompt_id]
      end
    end

    users_in_room = User.players.where(room_id: @current_room.id).count
    submitted_answers = Answer.where(game_prompt_id: params[:prompt_id], game_id: @current_room.current_game_id).count
    redirect_to_voting = submitted_answers >= users_in_room

    # All answers have been collected, time to vote
    if redirect_to_voting
      return redirect_to controller: "prompts", action: "voting", id: params[:prompt_id]
    end

    redirect_to controller: "prompts", action: "waiting", id: params[:prompt_id]
  end
end
