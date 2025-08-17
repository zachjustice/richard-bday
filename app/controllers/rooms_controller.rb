class RoomsController < ApplicationController
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
  def unauthorized
      render json: { "message": "Unauthorized" }, status: :unauthorized
  end

  def user_params
    params.expect(user: [ :name, :room ])
  end
end
