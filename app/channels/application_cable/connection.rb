module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection

      if self.current_user.role == User::CREATOR
        return
      end

      self.current_user.update(is_active: true)
      room = self.current_user.room
      Turbo::StreamsChannel.broadcast_append_to(
        "rooms:#{room.id}:users",
        target: "waiting-room",
        partial: "rooms/partials/user_list_item",
        locals: { user: self.current_user, action: "joined!" }
      )
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:users",
        action: :update,
        target: "waiting-room-players-count",
        html: "#{User.players.where(room: room).count} joined"
      )
    end

    def disconnect
      if !self.current_user
        return
      end

      # If the game has begun, don't set player as inactive since their phone could be asleep.
      if self.current_user.room.status != RoomStatus::WaitingRoom
        return
      end

      self.current_user.update(is_active: false)
      room = self.current_user.room
      if self.current_user.role == User::NAVIGATOR
        self.current_user.update(role: User::PLAYER)
        User.players.where(room: room).first&.update(role: User::NAVIGATOR)
      end

      Turbo::StreamsChannel.broadcast_remove_to(
        "rooms:#{room.id}:users",
        target: "waiting_room_user_#{self.current_user.id}"
      )
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:users",
        action: :update,
        target: "waiting-room-players-count",
        html: "#{User.players.where(room: room).count} joined"
      )
    end

    private
      def set_current_user
        # Check new cookie name first, fall back to old name for migration
        session_id = cookies.signed[:player_session_id]
        if session = Session.find_by(id: session_id)
          self.current_user = session.user
        end
      end
  end
end
