class Events
  module MessageType
    NextPrompt = "NextPrompt"
    NewUser = "NewUser"
  end

  def self.create_user_joined_room_event(user_name)
      { messageType: MessageType::NewUser, newUser: user.name }
  end

  def self.create_next_prompt_event(prompt_id)
      { messageType: MessageType::NextPrompt, prompt: prompt_id }
  end
end
