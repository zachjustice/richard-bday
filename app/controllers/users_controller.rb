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
    current_user = request.env["current_user"]

    @user = User.find(params[:id])
    if current_user && current_user.id == @user.id
      render json: {
        id: @user.id,
        name: @user.name,
        room: @user.room
      }
    else
      unauthorized
    end
  end

  private
    def unauthorized
        render json: { "message": "Unauthorized" }, status: :unauthorized
    end

    def user_params
      params.expect(user: [ :name, :room ])
    end
end
