class AnswersController < ApplicationController
  def create
    ans = Answer.new(
      text: params[:text],
      prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )
    successful = ans.save
    users_in_room = User.where(room_id: ans.room_id).count
    submitted_answers = Answer.where(prompt_id: ans.prompt_id, room_id: ans.room_id).count
    redirect_to_voting = submitted_answers >= users_in_room

    # All answers have been collected, time to vote
    if redirect_to_voting
      return redirect_to controller: "prompts", action: "voting", id: ans.prompt_id
    end

    if successful
      redirect_to controller: "prompts", action: "waiting", id: ans.prompt_id
    else
      redirect_to controller: "prompts", id: ans.prompt_id
    end
  end
end
