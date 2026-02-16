class UsersController < ApplicationController
  before_action :set_user, only: %i[edit update show]
  before_action :require_login, only: %i[edit update]
  before_action :authorize_user, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to root_path, notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show; end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    redirect_to root_path, alert: "Not authorized" unless current_user == @user
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
