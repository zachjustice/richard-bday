class DevPhaseSimulatorService
  Success = Data.define(:room)
  Failure = Data.define(:error)

  SUPPORTED_STATUSES = [
    RoomStatus::WaitingRoom,
    RoomStatus::StorySelection,
    RoomStatus::Answering
  ].freeze

  DEFAULT_PLAYER_COUNT_FOR_ANSWERING = User::MAX_PLAYERS

  def initialize(room:, target_status:, player_count: nil, audience_count: nil)
    @room = room
    @target_status = target_status
    @player_count = player_count
    @audience_count = audience_count
  end

  def call
    unless SUPPORTED_STATUSES.include?(@target_status)
      return Failure.new(error: "Unsupported target_status: #{@target_status.inspect}. Supported: #{SUPPORTED_STATUSES.inspect}")
    end

    if @target_status == RoomStatus::Answering
      @player_count ||= DEFAULT_PLAYER_COUNT_FOR_ANSWERING
    end

    seed_users if @player_count || @audience_count

    return Success.new(room: @room) if at_target_phase?

    case @target_status
    when RoomStatus::WaitingRoom
      seed_waiting_room
    when RoomStatus::StorySelection
      seed_story_selection
    when RoomStatus::Answering
      seed_answering
    end

    Success.new(room: @room)
  end

  private

  def at_target_phase?
    return false unless @room.status == @target_status

    case @target_status
    when RoomStatus::Answering
      @room.current_game&.dev_seeded? && @room.current_game.current_game_prompt_id.present?
    else
      true
    end
  end

  def seed_waiting_room
    if @room.current_game
      @room.current_game.update!(current_game_prompt: nil, dev_seeded: true)
    end
    @room.update!(
      status: RoomStatus::WaitingRoom,
      current_game: nil
    )
  end

  def seed_story_selection
    @room.update!(
      status: RoomStatus::StorySelection,
      current_game: nil
    )
  end

  def seed_answering
    story = Story.where(published: true).order(:title).first
    if story.nil?
      raise "DevPhaseSimulator cannot seed Answering: no published stories exist (Story.where(published: true).order(:title).first returned nil)"
    end

    game = Game.create!(story: story, room: @room, dev_seeded: true)
    first_game_prompt = create_game_prompts(story, game).first

    game.update!(current_game_prompt: first_game_prompt)
    @room.update!(
      status: RoomStatus::Answering,
      current_game: game
    )

    User.players.where(room: @room).update_all(status: UserStatus::Answering)
  end

  def create_game_prompts(story, game)
    blanks = Blank.where(story_id: story.id).order(:id)
    selected_prompts = []
    blanks.map.with_index do |blank, order|
      available = StoryPrompt.where(blank: blank).where.not(prompt_id: selected_prompts).order(:id)
      if available.empty?
        raise "DevPhaseSimulator: no prompts available for blank #{blank.id} (tags: #{blank.tags}) in story #{story.id}"
      end
      story_prompt = available.first
      selected_prompts << story_prompt.prompt_id
      GamePrompt.create!(
        game: game,
        prompt: story_prompt.prompt,
        blank: blank,
        order: order
      )
    end
  end

  def seed_users
    if @player_count
      target_players = @player_count.to_i
      current_player_count = User.players.where(room: @room).count

      if target_players > current_player_count
        Faker::Name.unique.clear
        (target_players - current_player_count).times do
          User.create!(
            room: @room,
            name: unique_fake_name(@room),
            role: User::PLAYER
          )
        end
      elsif target_players < current_player_count && @target_status == RoomStatus::Answering
        excess = current_player_count - target_players
        fake_players_scope(@room).order(:created_at).limit(excess).destroy_all
      end
    end

    if @audience_count
      target_audience = @audience_count.to_i
      current_audience_count = User.audience.where(room: @room).count
      (target_audience - current_audience_count).times do
        User.create!(
          room: @room,
          name: "DevAud#{SecureRandom.hex(3)}",
          role: User::AUDIENCE
        )
      end
    end
  end

  # A real player has a discord_id (Discord activity) or at least one Session
  # (web flow). Fake players have neither, so we trim only those.
  def fake_players_scope(room)
    User.players.where(room: room, discord_id: nil).where.missing(:sessions)
  end

  def unique_fake_name(room)
    existing_names = User.where(room: room).pluck(:name).to_set
    10.times do
      candidate = Faker::Name.unique.name[0...15]
      return candidate unless existing_names.include?(candidate)
    end
    "DevPlayer#{SecureRandom.hex(3)}"
  end
end
