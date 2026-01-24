class EditorInvitationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @invitation = EditorInvitation.find_by_token(params[:token])

    if @invitation.nil?
      redirect_to editor_login_path, alert: "Invalid invitation link."
    elsif @invitation.expired?
      redirect_to editor_login_path, alert: "This invitation has expired. Contact blanksies@zachjustice.dev for a new one."
    elsif @invitation.accepted?
      redirect_to editor_login_path, alert: "This invitation has already been used."
    else
      @editor = Editor.new(email: @invitation.email)
    end
  end

  def create
    @invitation = EditorInvitation.find_by_token(params[:token])

    unless @invitation&.valid_for_use?
      redirect_to editor_login_path, alert: "Invalid or expired invitation."
      return
    end

    @editor = Editor.new(editor_params.merge(email: @invitation.email))

    if @editor.save
      @invitation.mark_accepted!(@editor)
      start_new_editor_session_for(@editor)
      redirect_to after_editor_authentication_url, notice: "Welcome to Blanksies!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def editor_params
    params.require(:editor).permit(:username, :password)
  end
end
