class RoomsController < ApplicationController
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

  def user_params
    params.expect(user: [ :name, :room ])
  end
end
