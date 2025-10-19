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
      redirect_to controller: "rooms", action: "status", id: room_id
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
    # TODO updated, but might wrong!!
    current_game_prompt_order = room.current_game.current_game_prompt.order
    next_game_prompt_id = GamePrompt.find_by(game_id: room.current_game_id, order: current_game_prompt_order + 1)&.id
    if next_game_prompt_id.nil?
      return redirect_to controller: "rooms", action: "birthday", id: params[:id]
    end

    ActionCable.server.broadcast(
      "rooms:#{params[:id].to_i}",
      Events.create_next_prompt_event(next_game_prompt_id)
    )
    Room.find(params[:id]).update!(status: RoomStatus::Answering)
    room.current_game.update!(current_game_prompt_id: next_game_prompt_id)

    redirect_to controller: "rooms", action: "status", id: params[:id]
  end

  def status
    @room = Room.find(params[:id])
    @current_room = @room # Normally this is set by the session, but this is an unauthenticated page

    @users = User.where(room_id: @room.id)
    @status = @room.status
    if @status != RoomStatus::WaitingRoom
      @game_prompt = @room.current_game.current_game_prompt

      @answers = Answer.where(game_prompt_id: @game_prompt.id)
      @users_with_submitted_answers = @answers.map { |r| r.user.name }
      @answers_by_id = @answers.reduce({}) { |result, curr|
        result[curr.id] = curr
        result
      }

      @votes = Vote.where(game_prompt_id: @game_prompt.id)
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

        # I don't have good tie-break logic, so just choose at random
        # TODO replace with points.
        @winners[rand(@winners.length)].update!(won: true) unless @winners.empty?
      end
    end
  end

  def show
    @users = User.where(room_id: @current_room.id)
    # Redirect to the current prompt if the game for this room has advanced beyond the first prompt (index 0)
    if @current_room.status == RoomStatus::Answering
      redirect_to controller: "prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
      # TODO [room.current_prompt_index refactor] this elsif statement did the same thing as above. not sure why.
      # elsif @current_room.current_prompt_index > 0
      #  redirect_to controller: "prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
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
      logger.error "Failed to create room: #{room.errors.messages.to_json}"
      flash.notice = "Failed to create room: #{room.errors.full_messages.to_json}"
      redirect_to controller: "rooms", action: "create"
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

  def create_game_prompts(story, game)
    blanks = Blank.where(story_id: story.id)
    prompts = blanks.map do |b|
      # TODO: this will need to be more sophisticated
      # What if 2 blanks have the same tags. We want different prompts.
      # Do all prompt tags and blank tags need to match? required tags? optional tags? duplicate entries with different tags?
      Prompt.find_by(tags: b.tags)
    end
    puts("blanks.size", blanks.size)
    game_prompts = blanks.zip(prompts, (0...blanks.size)).map do |blank, prompt, order|
      puts("gameprompt:", blank.id, prompt.id, order)
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
