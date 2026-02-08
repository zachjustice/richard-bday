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

      # On reconnect: if this user has a smaller id than current navigator, reclaim navigator role
      if self.current_user.player?
        current_navigator = User.where(room: room, role: User::NAVIGATOR).first
        if current_navigator && self.current_user.id < current_navigator.id
          current_navigator.update(role: User::PLAYER)
          self.current_user.update(role: User::NAVIGATOR)
        elsif current_navigator.nil?
          self.current_user.update(role: User::NAVIGATOR)
        end
      end

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
      return if !self.current_user
      return if self.current_user.role == User::CREATOR

      room = self.current_user.room

      # Navigator reassignment runs in all game phases
      if self.current_user.role == User::NAVIGATOR
        self.current_user.update(role: User::PLAYER)
        User.players.where(room: room).where.not(id: self.current_user.id).order(:id).first&.update(role: User::NAVIGATOR)
      end

      # Only mark inactive and update waiting room UI during WaitingRoom phase
      # (phones may be asleep during active game)
      return if room.status != RoomStatus::WaitingRoom

      self.current_user.update(is_active: false)

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
        # Try Discord cable token first (passed as query param)
        if (cable_token = request.params[:cable_token])
          user_id = Rails.cache.read("cable_token:#{cable_token}")
          if user_id
            self.current_user = User.find_by(id: user_id)
            return self.current_user
          end
        end

        # Fall back to cookie-based auth
        session_id = cookies.signed[:player_session_id]
        if session = Session.find_by(id: session_id)
          self.current_user = session.user
        end
      end
  end
end
