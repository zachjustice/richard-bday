class PromptsController < ApplicationController
  def show
    @prompt = Prompt.find_by(params.permit(:id))
  end

  def waiting
    @prompt = Prompt.find_by(params.permit(:id))
    @users_with_submitted_answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id]).map { |r| r.user.name }
  end
end
