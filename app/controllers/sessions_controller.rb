class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    room = Room.find_by(params.permit(:code))
    if room.nil?
      return redirect_to new_session_path, alert: "Wrong room code."
    end

    if user = User.find_by(name: params[:name], room_id: room.id)
      return redirect_to new_session_path, alert: "Someone in this room already has that name."
    end

    user = User.new(name: params[:name], room_id: room.id)
    if user.save
      session[:user_id] = user.id
      puts("Setting user #{session[:user_id]}")
      # publish_user_joined_room(room.id, user.id)
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Someone in this room already has that name."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def publish_user_joined_room(room_id, user_id)
    event = UserJoinedRoom.new(data: { user_id: user_id, room_id: room_id })
    event_store.publish(event, stream_name: room_id)
  end
end
