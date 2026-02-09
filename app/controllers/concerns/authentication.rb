module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :editor_authenticated?, :current_editor
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_editor_authentication(**options)
      before_action :require_editor_auth, **options
    end

    def allow_unauthenticated_editor_access(**options)
      skip_before_action :require_editor_auth, **options
    end
  end

  private
    # ============ Player Authentication ============
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def require_editor_auth
      resume_editor_session || request_editor_authentication
    end

    def resume_session
      # Discord auth sets @current_user directly without setting Current.session.
      # This is intentional — Discord users don't have a Session record.
      find_session_by_discord_token || (Current.session ||= find_player_session_by_cookie)
    end

    def find_session_by_discord_token
      auth_header = request.headers["Authorization"]
      return nil unless auth_header&.start_with?("Bearer ")

      token = auth_header.sub("Bearer ", "")
      activity_token = DiscordActivityToken.find_by_token(token)

      if activity_token&.valid_token?
        @discord_authenticated = true
        @current_user = activity_token.user
        @current_room = @current_user.room
        activity_token
      end
    end

    def discord_authenticated?
      !!@discord_authenticated
    end

    def find_player_session_by_cookie
      session_id = cookies.signed[:player_session_id]

      if session_id
        session = Session.find_by(id: session_id)
        if session
          @current_user = User.find_by(id: session.user_id)
          @current_room = Room.find_by(id: @current_user.room_id) if @current_user
        end
        return session
      end

      nil
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || show_room_path
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |sess|
        Current.session = sess
        cookies.signed.permanent[:player_session_id] = { value: sess.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      ActionCable.server.disconnect(current_user: @current_user) if @current_user
      @current_user = nil
      Current.session&.destroy
      cookies.delete(:player_session_id)
    end

    # ============ Editor Authentication ============

    def editor_authenticated?
      resume_editor_session
    end

    def current_editor
      @current_editor ||= Current.editor_session&.editor
    end

    def resume_editor_session
      Current.editor_session ||= find_editor_session_by_cookie
    end

    def find_editor_session_by_cookie
      if cookies.signed[:editor_session_id]
        editor_session = EditorSession.find_by(id: cookies.signed[:editor_session_id])
        @current_editor = editor_session&.editor
        return editor_session
      end

      nil
    end

    def request_editor_authentication
      session[:return_to_after_editor_auth] = request.url
      redirect_to editor_login_path
    end

    def after_editor_authentication_url
      session.delete(:return_to_after_editor_auth) || stories_path
    end

    def start_new_editor_session_for(editor)
      editor.editor_sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |sess|
        Current.editor_session = sess
        cookies.signed.permanent[:editor_session_id] = { value: sess.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_editor_session
      @current_editor = nil
      Current.editor_session&.destroy
      cookies.delete(:editor_session_id)
    end
end
