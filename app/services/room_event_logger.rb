class RoomEventLogger
  class << self
    def log(room:, event_type:, game: nil, actor: nil, metadata: {})
      actor_type, actor_id = extract_actor_info(actor)

      RoomEvent.create!(
        room: room,
        game: game,
        event_type: event_type,
        actor_type: actor_type,
        actor_id: actor_id,
        metadata: metadata
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[RoomEventLogger] Failed to log event: #{e.message}")
      nil
    end

    # Convenience methods for common events
    def room_created(room:, actor:)
      log(room: room, event_type: RoomEvent::EventTypes::ROOM_CREATED, actor: actor)
    end

    def room_initialized(room:, actor:)
      log(room: room, event_type: RoomEvent::EventTypes::ROOM_INITIALIZED, actor: actor)
    end

    def game_started(room:, game:, actor:, story:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::GAME_STARTED,
        actor: actor,
        metadata: { story_id: story.id, story_title: story.title }
      )
    end

    def game_ended(room:, game:, actor:)
      log(room: room, game: game, event_type: RoomEvent::EventTypes::GAME_ENDED, actor: actor)
    end

    def player_joined(room:, user:)
      log(
        room: room,
        game: room.current_game,
        event_type: RoomEvent::EventTypes::PLAYER_JOINED,
        actor: user,
        metadata: { player_name: user.name, role: user.role, avatar: user.avatar }
      )
    end

    def answer_submitted(room:, game:, actor:, answer:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::ANSWER_SUBMITTED,
        actor: actor,
        metadata: {
          game_prompt_id: answer.game_prompt_id,
          text_preview: answer.text.to_s.truncate(30)
        }
      )
    end

    def answer_changed(room:, game:, actor:, game_prompt:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::ANSWER_CHANGED,
        actor: actor,
        metadata: { game_prompt_id: game_prompt.id }
      )
    end

    def vote_submitted(room:, game:, actor:, vote_info: {})
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::VOTE_SUBMITTED,
        actor: actor,
        metadata: vote_info
      )
    end

    def status_changed(room:, game: nil, from:, to:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::STATUS_CHANGED,
        actor: nil,
        metadata: { from: from, to: to }
      )
    end

    def answering_timer_expired(room:, game:, game_prompt:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::ANSWERING_TIMER_EXPIRED,
        actor: nil,
        metadata: { game_prompt_id: game_prompt.id }
      )
    end

    def voting_timer_expired(room:, game:, game_prompt:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::VOTING_TIMER_EXPIRED,
        actor: nil,
        metadata: { game_prompt_id: game_prompt.id }
      )
    end

    def next_prompt(room:, game:, actor:, next_game_prompt_id:)
      log(
        room: room,
        game: game,
        event_type: RoomEvent::EventTypes::NEXT_PROMPT,
        actor: actor,
        metadata: { next_game_prompt_id: next_game_prompt_id }
      )
    end

    def show_credits(room:, game:, actor:)
      log(room: room, game: game, event_type: RoomEvent::EventTypes::SHOW_CREDITS, actor: actor)
    end

    def start_new_game(room:, actor:)
      log(room: room, event_type: RoomEvent::EventTypes::START_NEW_GAME, actor: actor)
    end

    private

    def extract_actor_info(actor)
      return [ nil, nil ] unless actor

      case actor
      when User
        [ "User", actor.id ]
      when Editor
        [ "Editor", actor.id ]
      else
        [ actor.class.name, actor.id ]
      end
    end
  end
end
