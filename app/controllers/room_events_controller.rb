class RoomEventsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_any_authentication
  before_action :set_room

  def index
    @events = @room.room_events.reverse_chronological

    if params[:event_type].present?
      @events = @events.by_type(params[:event_type])
    end

    if params[:game_id].present?
      if params[:game_id] == "current"
        @events = @events.for_game(@room.current_game_id)
      elsif params[:game_id] != "all"
        @events = @events.for_game(params[:game_id])
      end
    end

    @events = @events.limit(500)
    @event_types = RoomEvent::EventTypes::ALL
    @games = Game.where(room_id: @room.id).order(created_at: :desc)
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def require_any_authentication
    # Allow access if authenticated player is in this room OR is an authenticated editor
    player_in_room = authenticated? && @current_user&.room_id == params[:room_id].to_i
    editor = editor_authenticated?

    unless player_in_room || editor
      flash[:alert] = "You must be in this room or logged in as an editor to view events"
      redirect_to root_path
    end
  end
end
