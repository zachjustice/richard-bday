class VotingTimesUpJob < ApplicationJob
  def perform(room, game_prompt_id)
    room.reload
    # Make sure this job is still valid.
    # The room status should be "Voting"
    # and the game_prompt_id arg should match the current_game_prompt_id on the current_game
    if room.status == RoomStatus::Voting && room.current_game.current_game_prompt_id == game_prompt_id
      GamePhasesService.new(room).move_to_results
    end
  end
end
