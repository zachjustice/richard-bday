class WaitingRoomChannel < ApplicationCable::Channel
  def follow(data)
    puts("FOLLOW! #{data}")
    stop_all_streams
    stream_from "rooms:#{data['room_id'].to_i}:new-user"
  end

  def unfollow
    stop_all_streams
  end
end
