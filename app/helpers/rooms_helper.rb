module RoomsHelper
  # Returns a hash with icon and text for a given room status
  def status_badge_content(status)
    case status
    when RoomStatus::WaitingRoom
      { icon: "⏳", text: "Waiting for Players" }
    when RoomStatus::Answering
      { icon: "✏️", text: "Answering" }
    when RoomStatus::Voting
      { icon: "🗳️", text: "Voting" }
    when RoomStatus::Results
      { icon: "🏆", text: "Results" }
    when RoomStatus::FinalResults
      { icon: "📜", text: "Final Story" }
    else
      { icon: "❓", text: "Unknown" }
    end
  end

  # Renders a status badge component
  def render_status_badge(status)
    content = status_badge_content(status)
    tag.div(class: "game-status-badge", data: { status: status }) do
      concat tag.span(content[:icon], class: "status-icon")
      concat tag.span(content[:text], class: "status-text")
    end
  end
end
