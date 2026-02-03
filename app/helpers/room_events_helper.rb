module RoomEventsHelper
  def render_event_description(event)
    case event.event_type
    when RoomEvent::EventTypes::ROOM_CREATED
      "Room created"
    when RoomEvent::EventTypes::ROOM_INITIALIZED
      "Room initialized, moving to story selection"
    when RoomEvent::EventTypes::GAME_STARTED
      story_title = event.metadata["story_title"] || "Unknown"
      "Game started with story: #{story_title}"
    when RoomEvent::EventTypes::GAME_ENDED
      "Game ended"
    when RoomEvent::EventTypes::PLAYER_JOINED
      player_name = event.metadata["player_name"] || "Unknown"
      avatar = event.metadata["avatar"] || ""
      "#{avatar} #{player_name} joined the room"
    when RoomEvent::EventTypes::ANSWER_SUBMITTED
      preview = event.metadata["text_preview"]
      preview.present? ? "Submitted answer: \"#{preview}\"" : "Submitted an answer"
    when RoomEvent::EventTypes::ANSWER_CHANGED
      "Changed their answer"
    when RoomEvent::EventTypes::VOTE_SUBMITTED
      if event.metadata["rankings"]
        "Submitted ranked votes"
      else
        "Submitted a vote"
      end
    when RoomEvent::EventTypes::STATUS_CHANGED
      from = event.metadata["from"]
      to = event.metadata["to"]
      "Status changed from #{from} to #{to}"
    when RoomEvent::EventTypes::ANSWERING_TIMER_EXPIRED
      "Answering timer expired"
    when RoomEvent::EventTypes::VOTING_TIMER_EXPIRED
      "Voting timer expired"
    when RoomEvent::EventTypes::NEXT_PROMPT
      "Advanced to next prompt"
    when RoomEvent::EventTypes::SHOW_CREDITS
      "Showing credits"
    when RoomEvent::EventTypes::START_NEW_GAME
      "Starting new game"
    else
      event.event_type.humanize
    end
  end

  def event_type_badge_class(event_type)
    case event_type
    when RoomEvent::EventTypes::ROOM_CREATED, RoomEvent::EventTypes::ROOM_INITIALIZED
      "bg-accent-secondary text-white"
    when RoomEvent::EventTypes::GAME_STARTED, RoomEvent::EventTypes::START_NEW_GAME
      "bg-accent-green text-white"
    when RoomEvent::EventTypes::GAME_ENDED
      "bg-accent-red text-white"
    when RoomEvent::EventTypes::PLAYER_JOINED
      "bg-accent-tertiary text-ink"
    when RoomEvent::EventTypes::ANSWER_SUBMITTED, RoomEvent::EventTypes::ANSWER_CHANGED
      "bg-accent-indigo text-white"
    when RoomEvent::EventTypes::VOTE_SUBMITTED
      "bg-accent-violet text-white"
    when RoomEvent::EventTypes::STATUS_CHANGED
      "bg-accent-orange text-white"
    when RoomEvent::EventTypes::ANSWERING_TIMER_EXPIRED, RoomEvent::EventTypes::VOTING_TIMER_EXPIRED
      "bg-accent-red/80 text-white"
    when RoomEvent::EventTypes::NEXT_PROMPT
      "bg-accent-secondary text-white"
    when RoomEvent::EventTypes::SHOW_CREDITS
      "bg-accent-tertiary text-ink"
    else
      "bg-gray-500 text-white"
    end
  end

  def relative_time_with_tooltip(time)
    return "" unless time

    relative = time_ago_in_words(time) + " ago"
    absolute = time.strftime("%Y-%m-%d %H:%M:%S")

    tag.span(relative, title: absolute, class: "cursor-help")
  end
end
