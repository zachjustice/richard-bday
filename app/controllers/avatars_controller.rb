class AvatarsController < ApplicationController
  def update
    new_avatar = params[:avatar]

    unless User::AVATARS.include?(new_avatar)
      return render_avatar_error("Invalid avatar selection")
    end

    old_avatar = @current_user.avatar
    @current_user.avatar = new_avatar

    if @current_user.save
      broadcast_avatar_update(old_avatar)
      render_avatar_success
    else
      @current_user.reload
      render_avatar_error("That avatar is already taken! Try another one.")
    end
  end

  private

  def broadcast_avatar_update(old_avatar)
    room = @current_user.room

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:users",
      target: ActionView::RecordIdentifier.dom_id(@current_user, :waiting_room),
      partial: "rooms/partials/user_list_item",
      locals: { user: @current_user }
    )
  end

  def render_avatar_success
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("avatar-display", partial: "avatars/current_avatar", locals: { user: @current_user }),
          turbo_stream.replace("avatar-picker", partial: "avatars/picker", locals: { user: @current_user, room: @current_user.room })
        ]
      end
    end
  end

  def render_avatar_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("avatar-picker", partial: "avatars/picker", locals: { user: @current_user, room: @current_user.room, error: message })
        ]
      end
    end
  end
end
