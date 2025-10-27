class RoomsController < ApplicationController
  allow_unauthenticated_access only: %i[ _create create ]
  include ActionController::Live

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

    game.update!(current_game_prompt_id: first_game_prompt_id)
    Room.find(room_id).update!(status: RoomStatus::Answering, current_game_id: game.id)

    ActionCable.server.broadcast(
      "rooms:#{room_id.to_i}",
      Events.create_next_prompt_event(first_game_prompt_id)
    )
    redirect_to controller: "rooms", action: "status", id: room_id
  end

  def next
    room = Room.find(params[:id])
    current_game_prompt_order = room.current_game.current_game_prompt.order
    next_game_prompt_id = GamePrompt.find_by(game_id: room.current_game_id, order: current_game_prompt_order + 1)&.id
    if next_game_prompt_id.nil?
      room.update!(status: RoomStatus::FinalResults)
      ActionCable.server.broadcast(
        "rooms:#{params[:id].to_i}",
        Events.create_final_results_event(next_game_prompt_id)
      )
      redirect_to controller: "rooms", action: "status", id: params[:id]
    else
      ActionCable.server.broadcast(
        "rooms:#{params[:id].to_i}",
        Events.create_next_prompt_event(next_game_prompt_id)
      )
      Room.find(params[:id]).update!(status: RoomStatus::Answering)
      room.current_game.update!(current_game_prompt_id: next_game_prompt_id)

      redirect_to controller: "rooms", action: "status", id: params[:id]
    end
  end

  def status
    room = Room.find(params[:id])
    unless @current_user&.role == User::CREATOR && @current_user.room_id == room.id
      flash[:alert] = "Only the room creator can view this page"
      return redirect_to root_path
    end

    status_data = RoomStatusService.new(params[:id]).call
    @status_data = status_data

    @room = status_data[:room]
    # Normally this is set by the session, but this is an unauthenticated page
    @current_room = status_data[:current_room]
    @users = status_data[:users]
    @status = status_data[:status]
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
<<<<<<< HEAD
=======
    @users = User.players.where(room_id: @current_room.id)
>>>>>>> creator and users?
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

  def end_game
    current_room = Room.find(params[:id])
    current_room.current_game.update!(
      current_game_prompt: nil
    )
    current_room.update!(
      status: RoomStatus::WaitingRoom,
      current_game: nil
    )
    redirect_to controller: "rooms", action: "status", id: params[:id]
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

  def create_game_prompts(story, game)
    blanks = Blank.where(story_id: story.id)
    prompts = blanks.map do |b|
      # TODO: this will need to be more sophisticated
      # What if 2 blanks have the same tags. We want different prompts.
      # Do all prompt tags and blank tags need to match? required tags? optional tags? duplicate entries with different tags?
      Prompt.find_by(tags: b.tags)
    end
    game_prompts = blanks.zip(prompts, (0...blanks.size)).map do |blank, prompt, order|
      GamePrompt.new(
        game: game,
        prompt: prompt,
        blank: blank,
        order: order
      )
    end
    !game_prompts.map(&:save!)
    game_prompts
  end
end
