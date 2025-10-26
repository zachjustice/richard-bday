class Events
  module MessageType
    NextPrompt = "NextPrompt"
    NewUser = "NewUser"
    AnswerSubmitted = "AnswerSubmitted"
    StartVoting = "StartVoting"
    VoteSubmitted = "VoteSubmitted"
    VotingDone =  "VotingDone"
    FinalResults = "FinalResults"
  end

  def self.create_user_joined_room_event(user_name)
      { messageType: MessageType::NewUser, newUser: user_name }
  end

  def self.create_next_prompt_event(game_prompt_id)
      { messageType: MessageType::NextPrompt, prompt: game_prompt_id }
  end

  def self.create_answer_submitted_event(user_name)
      { messageType: MessageType::AnswerSubmitted, user: user_name }
  end

  def self.create_start_voting_event(game_prompt_id)
      { messageType: MessageType::StartVoting, prompt: game_prompt_id }
  end

  def self.create_vote_submitted_event(vote)
      { messageType: MessageType::VoteSubmitted, prompt: vote.game_prompt_id, user: vote.user.name }
  end

  def self.create_voting_done_event(vote)
      { messageType: MessageType::VotingDone, prompt: vote.game_prompt_id }
  end

  def self.create_final_results_event(game_prompt_id)
      { messageType: MessageType::FinalResults, prompt: game_prompt_id }
  end
end
