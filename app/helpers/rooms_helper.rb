module RoomsHelper
    GAME_PHASES = [
      { icon: "✏️", text: "Answering", status: RoomStatus::Answering },
      { icon: "🗳️", text: "Voting", status: RoomStatus::Voting },
      { icon: "🏆", text: "Results", status: RoomStatus::Results }
    ]
end
