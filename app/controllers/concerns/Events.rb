class Events
  module MessageType
    NextPrompt = "NextPrompt"
    NewUser = "NewUser"
    AnswerSubmitted = "AnswerSubmitted"
  end

  def self.create_user_joined_room_event(user_name)
      { messageType: MessageType::NewUser, newUser: user_name }
  end

  def self.create_next_prompt_event(prompt_id)
      { messageType: MessageType::NextPrompt, prompt: prompt_id }
  end

  def self.create_answer_submitted_event(user_name)
      { messageType: MessageType::AnswerSubmitted, user: user_name }
  end
end
