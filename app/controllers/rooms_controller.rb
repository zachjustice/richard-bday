class RoomsController < ApplicationController
  include ActionController::Live
  allow_unauthenticated_access only: %i[ _create create ]
  before_action :in_room?, except: %i[ _create create ]

  def initialize_room
    room = Room.find(params[:id])

    unless @current_user&.role == User::CREATOR && @current_user.room_id == room.id
      flash[:alert] = "Only the room creator can initialize the game"
      return redirect_to room_status_path(room)
    end

    room.update!(status: RoomStatus::StorySelection)

    status_data = RoomStatusService.new(room).call
    GamePhasesService.new(room).update_room_status_view("rooms/status/story_selection", status_data)

    redirect_to room_status_path(room)
  end

  def start
    story_id = params[:story]
    room_id = params[:id]

    story = Story.find(story_id)
    game = Game.new(
      story_id: story_id,
      room_id: room_id,
    )
    if !game.save
      flash.notice = "Couldn't start game: #{game.errors.full_messages}"
      return redirect_to controller: "rooms", action: "status", id: room_id
    end

    first_game_prompt_id = create_game_prompts(story, game).first.id

    room = Room.find(room_id)
    room.update!(current_game_id: game.id)

    move_to_next_game_prompt(room, first_game_prompt_id)
    redirect_to controller: "rooms", action: "status", id: room_id
  end

  def update_settings
    room = Room.find(params[:id])

    if @current_user&.role != User::CREATOR || @current_user.room_id != room.id
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "settings-form",
            partial: "rooms/settings/settings_error",
            locals: { error: "Only the room creator can update settings" }
          )
        end
      end
      return
    end

    if room.update(settings_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "settings-form",
            partial: "rooms/settings/settings_form",
            locals: { room: room, form_saved: true }
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "settings-form",
            partial: "rooms/settings/settings_form",
            locals: { room: room, form_saved: false }
          )
        end
      end
    end
  end

  # Called by the user with the navigator role (first user to join room) to advance to the next prompt.
  # this calls needs to trigger updating the room status view, broadcast the next prompt or final results events, and redirect to the next prompt
  def next
    room = Room.find(params[:id])
    prev_game_prompt_id = room.current_game.current_game_prompt_id
    current_game_prompt_order = room.current_game.current_game_prompt.order
    next_game_prompt_id = GamePrompt.find_by(game_id: room.current_game_id, order: current_game_prompt_order + 1)&.id

    if next_game_prompt_id.nil?
      room.update!(status: RoomStatus::FinalResults)

      status_data = RoomStatusService.new(room).call
      GamePhasesService.new(room).update_room_status_view("rooms/status/final_results", status_data)

      ActionCable.server.broadcast(
        "rooms:#{params[:id].to_i}",
        Events.create_final_results_event(prev_game_prompt_id)
      )
      redirect_to controller: "prompts", action: "results", id: prev_game_prompt_id
    else
      move_to_next_game_prompt(room, next_game_prompt_id)
      status_data = RoomStatusService.new(room).call
      GamePhasesService.new(room).update_room_status_view("rooms/status/answering", status_data)
      redirect_to controller: "prompts", action: "show", id: next_game_prompt_id
    end
  end

  def status
    room = Room.find(params[:id])
    unless @current_user&.role == User::CREATOR && @current_user.room_id == room.id
      flash[:alert] = "Only the room creator can view this page"
      return redirect_to root_path
    end

    status_data = RoomStatusService.new(room).call
    @status_data = status_data

    @room = status_data[:room]
    # Normally this is set by the session, but this is an unauthenticated page
    @current_room = status_data[:current_room]
    @users = status_data[:users]
    @status = status_data[:status]
    @total_game_prompts = status_data[:total_game_prompts]
    @game_prompt = status_data[:game_prompt]
    @answers = status_data[:answers]
    @users_with_submitted_answers = status_data[:users_with_submitted_answers]
    @answers_by_id = status_data[:answers_by_id]
    @votes = status_data[:votes]
    @users_with_vote = status_data[:users_with_vote]
    @votes_by_answer = status_data[:votes_by_answer]
    @winners = status_data[:winners]
    @winner = status_data[:winner]
    @story = status_data[:story]
  end

  def show
    @users = User.players.where(room_id: @current_room.id)
    # Redirect to the current prompt if the game for this room has advanced beyond the first prompt (index 0)
    if @current_room.status == RoomStatus::Answering
      redirect_to controller: "prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
    end
  end

  # GET /rooms/create -> rooms#create
  def create
  end

  # POST /rooms/create -> rooms#_create
  def _create
    code = (0...4).map { ("a".."z").to_a[rand(26)] }.join
    room = Room.new(code: code)

    if room.save
      # Create a temporary Creator user for the room creator
      creator_name = "Creator-#{code}"
      creator_user = User.new(
        name: creator_name,
        room_id: room.id,
        role: User::CREATOR
      )

      if creator_user.save
        start_new_session_for creator_user
        redirect_to controller: "rooms", action: "status", id: room.id
      else
        logger.error "Failed to create creator user: #{creator_user.errors.messages.to_json}"
        flash.notice = "Failed to create room: #{creator_user.errors.full_messages.to_json}"
        redirect_to controller: "rooms", action: "create"
      end
    else
      logger.error "Failed to create room: #{room.errors.messages.to_json}"
      flash.notice = "Failed to create room: #{room.errors.full_messages.to_json}"
      redirect_to controller: "rooms", action: "create"
    end
  end

  # called by the user with the navigator role (first user to join room) to end the game.
  def end_game
    current_room = Room.find(params[:id])
    current_room.current_game&.update!(
      current_game_prompt: nil
    )
    current_room.update!(
      status: RoomStatus::WaitingRoom,
      current_game: nil
    )

    ActionCable.server.broadcast(
      "rooms:#{current_room.id}",
      Events.create_new_game_event(current_room.id)
    )
    status_data = RoomStatusService.new(current_room).call
    GamePhasesService.new(current_room).update_room_status_view("rooms/status/waiting_room", status_data, true)
    redirect_to controller: "rooms", action: "waiting_for_new_game", id: params[:id]
  end

  def waiting_for_new_game
  end

  private

  def in_room?
    # Check if the user is in the room if a room specific page is being accessed.
    if params[:id] && @current_user&.room_id != params[:id].to_i
      flash[:notice] = "Navigating you to the right room..."
      redirect_to controller: "rooms", id: @current_user&.room_id, action: "status"
    end
  end

  def move_to_next_game_prompt(room, next_game_prompt_id)
    ActionCable.server.broadcast(
      "rooms:#{room.id}",
      Events.create_next_prompt_event(next_game_prompt_id)
    )
    room.update!(status: RoomStatus::Answering)
    next_game_phase_time = Time.now + room.time_to_answer_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS
    room.current_game.update!(current_game_prompt_id: next_game_prompt_id, next_game_phase_time: next_game_phase_time)

    # Start timer for answers
    AnsweringTimesUpJob.set(wait_until: next_game_phase_time).perform_later(room, next_game_prompt_id)
  end

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def room_params
    params.expect(room: [ :code ])
  end

  def create_game_prompts(story, game)
    blanks = Blank.where(story_id: story.id)
    selected_prompts = []
    game_prompts = blanks.map.with_index do |blank, order|
      # Select a random unchosen prompt associated with this story
      available = StoryPrompt.where(blank: blank).where.not(id: selected_prompts)
      if available.empty?
        raise "No prompts available for blank #{blank.id} (tags: #{blank.tags}) in story #{story.id}"
      end
      story_prompt = available.sample
      selected_prompts << story_prompt.prompt_id
      GamePrompt.create!(
        game: game,
        prompt: story_prompt.prompt,
        blank: blank,
        order: order
      )
    end
    game_prompts
  end

  def settings_params
    params.require(:room).permit(:time_to_answer_seconds, :time_to_vote_seconds)
  end
end
