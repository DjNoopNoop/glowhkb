class AccountController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    render 'account/show'
  end

  def edit
    @user = current_user
    render 'account/edit'
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to account_path, notice: 'Profile updated'
    else
      render 'account/edit', status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
