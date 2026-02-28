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
    if @user.update(profile_params)
      redirect_to account_path, notice: 'Profile updated'
    else
      flash.now[:alert] = 'Profile update failed. See errors below.'
      render 'account/edit', status: :unprocessable_entity
    end
  end

  # Separate password update so changing password is handled independently
  def update_password
    @user = current_user
    pw = password_params[:password]
    pwc = password_params[:password_confirmation]

    if pw.blank?
      @user.errors.add(:password, "can't be blank")
      flash.now[:alert] = 'Please enter a password.'
      render 'account/edit', status: :unprocessable_entity
      return
    end

    if pw != pwc
      @user.errors.add(:password_confirmation, "doesn't match Password")
      flash.now[:alert] = "Password confirmation doesn't match."
      render 'account/edit', status: :unprocessable_entity
      return
    end

    if @user.update(password: pw, password_confirmation: pwc)
      redirect_to account_path, notice: 'Password updated'
    else
      flash.now[:alert] = 'Could not update password. See errors below.'
      render 'account/edit', status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:username, :email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
