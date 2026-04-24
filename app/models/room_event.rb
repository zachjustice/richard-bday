class RoomEvent < ApplicationRecord
  module EventTypes
    ROOM_CREATED = "room_created"
    ROOM_INITIALIZED = "room_initialized"
    GAME_STARTED = "game_started"
    GAME_ENDED = "game_ended"
    PLAYER_JOINED = "player_joined"
    ANSWER_SUBMITTED = "answer_submitted"
    ANSWER_CHANGED = "answer_changed"
    VOTE_SUBMITTED = "vote_submitted"
    STATUS_CHANGED = "status_changed"
    ANSWERING_TIMER_EXPIRED = "answering_timer_expired"
    VOTING_TIMER_EXPIRED = "voting_timer_expired"
    NEXT_PROMPT = "next_prompt"
    SHOW_CREDITS = "show_credits"
    START_NEW_GAME = "start_new_game"

    ALL = [
      ROOM_CREATED, ROOM_INITIALIZED, GAME_STARTED, GAME_ENDED,
      PLAYER_JOINED, ANSWER_SUBMITTED, ANSWER_CHANGED, VOTE_SUBMITTED,
      STATUS_CHANGED, ANSWERING_TIMER_EXPIRED, VOTING_TIMER_EXPIRED,
      NEXT_PROMPT, SHOW_CREDITS, START_NEW_GAME
    ].freeze
  end

  belongs_to :room
  belongs_to :game, optional: true

  validates :event_type, presence: true, inclusion: { in: EventTypes::ALL }

  before_validation :set_event_time_at, on: :create

  scope :chronological, -> { order(event_time_at: :asc) }
  scope :reverse_chronological, -> { order(event_time_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :for_game, ->(game_id) { where(game_id: game_id) }

  def actor
    return nil unless actor_type && actor_id
    actor_type.constantize.find_by(id: actor_id)
  end

  def actor_display_name
    return "System" unless actor_type && actor_id

    # Use cached actor_name from metadata if available
    cached_name = metadata&.dig("actor_name")
    return cached_name if cached_name.present?

    # Fallback to database lookup
    case actor_type
    when "User"
      user = User.find_by(id: actor_id)
      user ? "#{user.avatar} #{user.name}" : "Unknown User"
    when "Editor"
      editor = Editor.find_by(id: actor_id)
      editor ? editor.username : "Unknown Editor"
    else
      "Unknown"
    end
  end

  def system_event?
    actor_type.nil? && actor_id.nil?
  end

  private

  def set_event_time_at
    self.event_time_at ||= Time.current
  end
end
