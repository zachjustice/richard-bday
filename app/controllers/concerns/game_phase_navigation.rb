module GamePhaseNavigation
  extend ActiveSupport::Concern

  private

  def path_for_current_phase(room, user)
    prompt = room.current_game&.current_game_prompt
    return show_room_path unless prompt

    case room.status
    when RoomStatus::Voting
      game_prompt_voting_path(prompt)
    when RoomStatus::Results, RoomStatus::FinalResults
      game_prompt_results_path(prompt)
    when RoomStatus::Credits, RoomStatus::StorySelection
      show_room_path
    when RoomStatus::Answering
      user.audience? ? game_prompt_waiting_path(prompt) : game_prompt_path(prompt)
    when RoomStatus::WaitingRoom
      waiting_for_new_game_path(room)
    else
      show_room_path
    end
  end
end
