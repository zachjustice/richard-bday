class EditorPasswordResetsController < ApplicationController
  allow_unauthenticated_access

  # Rate limit: 5 requests per 10 minutes per IP
  rate_limit to: 5, within: 10.minutes, only: [ :create ],
    with: -> { redirect_to editor_forgot_password_path, alert: "Too many requests. Please try again later." }

  def new
  end

  def create
    email = params[:email]&.downcase&.strip

    # Per-email rate limiting
    recent_resets = EditorPasswordReset.joins(:editor)
                      .where(editors: { email: email })
                      .where("editor_password_resets.created_at > ?", 10.minutes.ago)
                      .count

    if recent_resets >= 3
      redirect_to editor_forgot_password_path,
        alert: "Too many reset requests for this email. Please try again later."
      return
    end

    editor = Editor.find_by(email: email)

    if editor
      reset, token = EditorPasswordReset.create_with_token(editor: editor)
      if token
        EditorMailer.password_reset(editor, token).deliver_later

        # Log magic link in non-production for testing
        unless Rails.env.production?
          reset_url = editor_reset_password_url(token: token)
          Rails.logger.info "Password reset link (dev only): #{reset_url}"
        end
      end
    end

    # Always show same message to prevent email enumeration
    redirect_to editor_login_path,
      notice: "If an account exists with that email, you will receive reset instructions."
  end

  def edit
    @reset = EditorPasswordReset.find_by_token(params[:token])

    if @reset.nil?
      redirect_to editor_login_path, alert: "Invalid reset link."
    elsif @reset.expired?
      redirect_to editor_login_path, alert: "This reset link has expired."
    elsif @reset.used?
      redirect_to editor_login_path, alert: "This reset link has already been used."
    end
  end

  def update
    @reset = EditorPasswordReset.find_by_token(params[:token])

    unless @reset&.valid_for_use?
      redirect_to editor_login_path, alert: "Invalid or expired reset link."
      return
    end

    if params[:password].blank?
      flash.now[:alert] = "Password cannot be blank"
      return render :edit, status: :unprocessable_entity
    end

    if @reset.editor.update(password: params[:password])
      @reset.mark_used!
      # Invalidate all existing sessions for security
      @reset.editor.editor_sessions.destroy_all
      redirect_to editor_login_path, notice: "Password updated successfully. Please log in."
    else
      flash.now[:alert] = @reset.editor.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end
end
