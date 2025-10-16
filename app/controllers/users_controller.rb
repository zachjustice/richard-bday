class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    @user = User.new(user_params)
    if @user.save
      render json: {
        secret: Auth.encrypt(@user.id)
      }
    else
      render json: { "message": "User couldn't be created successfully." }, status: :unprocessable_content
    end
  end

  def show
    user = User.find_by_id(params[:id] || current_user.id)
    if current_user && user && current_user.id == user.id
      @user = user
    else
      unauthorized
    end
  end

  private

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def unauthorized
      render json: { "message": "Unauthorized" }, status: :unauthorized
  end

  def user_params
    params.expect(user: [ :name, :room ])
  end
end
