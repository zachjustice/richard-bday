class RoomsController < ApplicationController
  allow_unauthenticated_access only: %i[ _create create ]
  include ActionController::Live

  def start
    prompt_id = GamePromptOrder.prompts().first
    ActionCable.server.broadcast(
      "rooms:#{params[:id].to_i}",
      Events.create_next_prompt_event(prompt_id)
    )
    Room.find(params[:id]).update!(status: RoomStatus::Answering, current_prompt_index: 0)

    redirect_to controller: "rooms", action: "status", id: params[:id]
  end

  def next
    room = Room.find(params[:id])
    next_prompt_id = GamePromptOrder.prompts()[room.current_prompt_index + 1]
    if next_prompt_id.nil?
      return redirect_to controller: "rooms", action: "birthday", id: params[:id]
    end

    ActionCable.server.broadcast(
      "rooms:#{params[:id].to_i}",
      Events.create_next_prompt_event(next_prompt_id)
    )
    Room.find(params[:id]).update!(status: RoomStatus::Answering, current_prompt_index: room.current_prompt_index + 1)

    redirect_to controller: "rooms", action: "status", id: params[:id]
  end

  def status
    @room = Room.find(params[:id])
    @current_room = @room # Normally this is set by the session, but this is an unauthenticated page
    @status = @room.status
    @current_prompt_id = GamePromptOrder.prompts()[@room.current_prompt_index]

    @users = User.where(room: @room)
    @prompt = Prompt.find(@current_prompt_id)

    @answers = Answer.where(prompt_id: @prompt.id, room_id: @room.id)
    @users_with_submitted_answers = @answers.map { |r| r.user.name }
    @answers_by_id = @answers.reduce({}) { |result, curr|
      result[curr.id] = curr
      result
    }

    @votes = Vote.where(prompt: @prompt, room: @room)
    @votes_by_answer = {}
    most_votes = -1
    @winners = []

    # Only calculate winners if all the votes are in. Front-end will use existence of @winners to determine if voting is done.
    if @status == RoomStatus::Results
      @votes.each do |vote|
        if @votes_by_answer[vote.answer_id].nil?
          @votes_by_answer[vote.answer_id] = []
        end
        @votes_by_answer[vote.answer_id].push(vote)
        if @votes_by_answer[vote.answer_id].size > most_votes
          most_votes = @votes_by_answer[vote.answer_id].size
          @winners = [ @answers_by_id[vote.answer_id] ]
        elsif @votes_by_answer[vote.answer_id].size == most_votes
          @winners.push(@answers_by_id[vote.answer_id])
        end
      end

      @winners[rand(@winners.length)].update!(won: true) unless @winners.empty?
    end
  end

  def show
    @users = User.where(room: @current_room)
    # Redirect to the current prompt if the game for this room has advanced beyond the first prompt (index 0)
    if @current_room.status == RoomStatus::Answering
      redirect_to controller: "prompts", action: "show", id: GamePromptOrder.prompts()[@current_room.current_prompt_index]
    elsif @current_room.current_prompt_index > 0
      redirect_to controller: "prompts", action: "show", id: GamePromptOrder.prompts()[@current_room.current_prompt_index]
    end
  end

  # GET /rooms/create -> rooms#create
  def create
  end

  # POST /rooms/create -> rooms#_create
  def _create
    code = (0...4).map { ("a".."z").to_a[rand(26)] }.join
    room = Room.new(code: code)

    # todo grab first user to use as an 'admin' user. ideally there'd be user types, but hack.
    start_new_session_for User.find(1)
    if room.save
      redirect_to controller: "rooms", action: "status", id: room.id
    else
      redirect_to controller: "rooms", action: "create", alert: "Failed."
    end
  end

  def birthday
    story_template = """
    Richard was born on [REDACTED] to his loving parents Kirk and Lisa. He weighed %s lbs %s oz,
    and was described by the doctors and nurses as %s. As a baby, Richard was %s. For example, he
    would only %s when you %s.

    As a toddler and child, Richard loved to play on the playground. His favorite activity was %s.
    One day, he met some other children on the playground Eli, Michael, Claire, and John. On the playground,
    they pretended to be %s and %s. They had a great time and became friends forever.

    As they grew up, Richard, Eli, Michael, John and Claire stayed friends. One day, Michael and Eli
    met Paula at the Lucky Dog. Paula heard them talking about %s in Dungeons and Dragons, and asked to
    join their D&D group. When Paula first met Richard, she was instantly smitten when Richard %s.
    After that, it was impossible for them to not fall madly in love and get married.

    Together they pursued their dreams. Richard became a famous puzzle maker when he got on the news for
    %s. Paula's voice acting won world-wide acclaim when she performed a parody of %s %s.

    They also had many adventures together. There most unforgettable trip was in %s when Richard %s and
    Paula had to %s. They would always cherish the memories they shared together.

    Finally, after many years together, Richard and Paula died together at the age of %s surrounded by
    their %s cats.
    """
    answers = Answer.where(room_id: params[:id], won: true).map { |p| p.text }
    complete_story = story_template % answers
    @story = complete_story.split(".").map { |s| s.strip + "."  }
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
