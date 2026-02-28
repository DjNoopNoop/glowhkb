class PasswordResetsController < ApplicationController
  # No login required to request a reset

  def new
  end

  def create
    @user = User.find_by(email: params[:email].to_s.downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      redirect_to login_path, notice: 'Password reset instructions have been sent to your email.'
    else
      flash.now[:alert] = 'Email address not found.'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find_by(email: params[:email].to_s.downcase)
    unless @user && @user.authenticated?(:reset, params[:id]) && !@user.password_reset_expired?
      redirect_to new_password_reset_path, alert: 'Password reset link is invalid or has expired.'
    end
  end

  def update
    @user = User.find_by(email: params[:email].to_s.downcase)
    unless @user && @user.authenticated?(:reset, params[:id])
      redirect_to new_password_reset_path, alert: 'Password reset link is invalid.'
      return
    end

    if params[:user][:password].blank?
      @user.errors.add(:password, "can't be blank")
      flash.now[:alert] = 'Password cannot be blank.'
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
      # Clear reset digest to prevent reuse
      @user.update_columns(reset_digest: nil, reset_sent_at: nil)
      redirect_to login_path, notice: 'Password has been reset. You can now sign in.'
    else
      flash.now[:alert] = 'Unable to reset password. See errors below.'
      render :edit, status: :unprocessable_entity
    end
  end
end
