module GamePhaseNavigation
  extend ActiveSupport::Concern

  private

  def path_for_current_phase(room, user)
    prompt = room.current_game&.current_game_prompt

    case room.status
    when RoomStatus::StorySelection
      show_room_path
    when RoomStatus::WaitingRoom
      waiting_for_new_game_path(room)
    when RoomStatus::FinalResults
      room_story_path(room)
    when RoomStatus::Credits
      room_game_credits_path(room)
    when RoomStatus::Answering
      return show_room_path unless prompt
      if user.audience? || user.answered?
        game_prompt_waiting_path(prompt)
      else
        game_prompt_path(prompt)
      end
    when RoomStatus::Voting
      return show_room_path unless prompt
      if user.audience? || !user.voted?
        game_prompt_voting_path(prompt)
      else
        game_prompt_results_path(prompt)
      end
    when RoomStatus::Results
      return show_room_path unless prompt
      game_prompt_results_path(prompt)
    else
      show_room_path
    end
  end
end
