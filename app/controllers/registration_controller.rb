class RegistrationController < ApplicationController
  def new
    @user = User.new
    render 'registration/new'
  end

  def create
    permitted = sanitize_role(user_params)
    @user = User.new(permitted)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Account created'
    else
      render 'registration/new', status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end

  def sanitize_role(permitted_params)
    rp = permitted_params.to_h
    rp[:role] = User.public_roles.include?(rp[:role]) ? rp[:role] : User::ROLE_CONTRIBUTOR
    rp
  end
end
