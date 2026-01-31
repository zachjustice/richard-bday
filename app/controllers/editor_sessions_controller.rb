class EditorSessionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: [ :create ], with: -> { redirect_to editor_login_path, alert: "Try again later." }

  def new
    # Already logged in as editor? Redirect to dashboard
    if editor_authenticated?
      redirect_to stories_path
    end
  end

  def create
    editor = Editor.find_by(username: params[:username])

    if editor&.authenticate(params[:password])
      start_new_editor_session_for(editor)
      redirect_to after_editor_authentication_url
    else
      flash.now[:alert] = "Invalid username or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_editor_session
    redirect_to editor_login_path, notice: "You have been logged out."
  end
end
