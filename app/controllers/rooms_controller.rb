class RoomsController < ApplicationController
  include ActionController::Live

  def start
    prompt_id = 1
    ActionCable.server.broadcast(
      "rooms:#{params[:id].to_i}",
      Events.create_next_prompt_event(prompt_id)
    )

    redirect_to controller: "prompts", action: "show", id: prompt_id
  end

  def show
    @room = Room.find(current_user.room_id)
    @users = User.where(room_id: @room.id)
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      render json: {
        secret: Auth.encrypt(@room.id)
      }
    else
      render json: { "message": "Room couldn't be created successfully." }, status: unprocessable_content
    end
  end

  private

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def unauthorized
      render json: { "message": "Unauthorized" }, status: :unauthorized
  end

  def room_params
    params.expect(room: [ :code ])
  end
end
