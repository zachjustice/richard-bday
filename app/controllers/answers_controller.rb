class AnswersController < ApplicationController
  def create
    answer = Answer.find_or_initialize_by(
      game_prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      game_id: @current_room.current_game_id
    )
    answer.text = params[:text]

    if !answer.save
      flash[:alert] = answer.errors.full_messages.join(", ")
      return redirect_to controller: "game_prompts", action: "show", id: params[:prompt_id]
    end

    users_in_room = User.players.where(room_id: @current_room.id).count
    submitted_answers = Answer.where(game_prompt_id: params[:prompt_id], game_id: @current_room.current_game_id).count
    redirect_to_voting = submitted_answers >= users_in_room

    # All answers have been collected, time to vote
    if redirect_to_voting
      return redirect_to controller: "game_prompts", action: "voting", id: params[:prompt_id]
    end

    redirect_to controller: "game_prompts", action: "waiting", id: params[:prompt_id]
  end
end
