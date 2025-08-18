class AnswersController < ApplicationController
  def create
    ans = Answer.new(
      text: params[:text],
      prompt_id: params[:prompt_id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    if ans.save
      redirect_to controller: "prompts", action: "waiting", id: ans.prompt_id
    end
  end
end
