class PromptsController < ApplicationController
  def show
    @prompt = Prompt.find_by(params.permit(:id))
  end

  def waiting
    @prompt = Prompt.find_by(params.permit(:id))
    @users_with_submitted_answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id]).map { |r| r.user.name }
  end

  def voting
    @prompt = Prompt.find_by(params.permit(:id))
    @answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id])
  end

  def results
    @prompt = Prompt.find_by(params.permit(:id))
    @votes = Vote.where(room_id: @current_room.id, prompt_id: params[:id])
  end
end
