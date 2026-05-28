class DevPhaseSimulatorService
  Success = Data.define(:room)
  Failure = Data.define(:error)

  SUPPORTED_STATUSES = [
    RoomStatus::WaitingRoom,
    RoomStatus::StorySelection
  ].freeze

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

    seed_users if @player_count || @audience_count

    return Success.new(room: @room) if @room.status == @target_status

    case @target_status
    when RoomStatus::WaitingRoom
      seed_waiting_room
    when RoomStatus::StorySelection
      seed_story_selection
    end

    Success.new(room: @room)
  end

  private

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

  def seed_users
    target_players = @player_count.to_i
    target_audience = @audience_count.to_i

    current_player_count = User.players.where(room: @room).count
    (target_players - current_player_count).times do |i|
      User.create!(
        room: @room,
        name: "DevPlayer#{SecureRandom.hex(3)}",
        role: User::PLAYER
      )
    end

    current_audience_count = User.audience.where(room: @room).count
    (target_audience - current_audience_count).times do |i|
      User.create!(
        room: @room,
        name: "DevAud#{SecureRandom.hex(3)}",
        role: User::AUDIENCE
      )
    end
  end
end
