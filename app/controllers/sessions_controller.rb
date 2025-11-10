class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create resume ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    session_id = cookies.signed[:session_id]
    if session_id
      session = Session.find_by(id: session_id)
      @room = session&.user&.room
    end
  end

  def resume
    # Disable resume endpoint in production
    raise ActionController::RoutingError, "Not Found" if Rails.env.production?

    # check for current session before allowing user to start a new session.
    # i.e. if user hits back or revisits this page.
    code = params[:code]&.downcase
    room = Room.find_by(code: code)
    if room.nil?
      return redirect_to new_session_path, alert: "Wrong room code."
    end

    user = User.find_by(name: params[:name], room_id: room.id)
    if user.nil?
      return redirect_to new_session_path, alert: "Wrong user name."
    end

    session[:user_id] = user.id
    @current_user = user
    @current_room = room
    start_new_session_for user
    redirect_to after_authentication_url
  end

  def create
    # Get room
    session_id = cookies.signed[:session_id]
    code = params[:code]&.downcase
    if session_id
      room = Session.find(session_id).user.room
      if room.code == code
        return redirect_to after_authentication_url
      end
    end

    room = Room.find_by(code: code)
    if room.nil?
      return redirect_to new_session_path, alert: "Wrong room code."
    end

    if user = User.find_by(name: params[:name], room_id: room.id)
      return redirect_to new_session_path, alert: "Someone in this room already has that name."
    end

    current_users = User.players.where(room_id: room.id).count
    user_role = current_users == 0 ? User::NAVIGATOR : User::PLAYER
    # The first user to join the room is the navigator. They are allowed to press the "next" button to advance rounds and change settings.
    user = User.new(name: params[:name], room_id: room.id, role: user_role)

    if user.save
      session[:user_id] = user.id
      @current_user = user
      @current_room = room
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Someone in this room already has that name."
    end
  end

  def editor
  end

  def create_editor
    # Get room
    code = params[:code]
    room = Room.find_by(code: code)
    if room.nil?
      return redirect_to new_session_path, alert: "Wrong room code."
    end

    # Gotta know the secret to get in here. This is set manually in production to a random secret. :)
    if code != Room.first.code
      return redirect_to after_authentication_url
    end

    if user = User.find_by(name: params[:name], room_id: room.id)
      session[:user_id] = user.id
      @current_user = user
      @current_room = room
      start_new_session_for user
      return redirect_to stories_path
    end

    user = User.new(name: params[:name], room_id: room.id, role: User::EDITOR)

    if user.save
      session[:user_id] = user.id
      @current_user = user
      @current_room = room
      start_new_session_for user
      redirect_to stories_path
    else
      redirect_to new_session_path, alert: "Someone in this room already has that name."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
