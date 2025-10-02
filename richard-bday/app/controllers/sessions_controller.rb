class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    # check for current session before allowing user to start a new session.
    # i.e. if user hits back or revisits this page.
    session_id = cookies.signed[:session_id]
    if session_id && Session.find_by(id: session_id)
      redirect_to after_authentication_url
    end
  end

  def create
    # check for current session before allowing user to start a new session.
    # i.e. if user hits back or revisits this page.
    if session[:user_id]
      return redirect_to after_authentication_url
    end

    # Get room
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
      @current_user = user
      @current_room = room
      start_new_session_for user
      puts ("after_authentication_url: #{after_authentication_url}")
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Someone in this room already has that name."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
