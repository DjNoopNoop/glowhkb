class SessionsController < ApplicationController
  def new; end

  def create
    # Allow users to sign in with either email or username
    login = params[:email].to_s.strip
    user = User.find_by(email: login) || User.find_by(name: login)
    if user&.authenticate(params[:password])
      if user.active?
        session[:user_id] = user.id
        redirect_to root_path, notice: "Signed in"
      else
        message = user.denied? ? "Your account has been denied." : "Your account is pending approval."
        flash.now[:alert] = message
        render :new, status: :forbidden
      end
    else
      flash.now[:alert] = "Invalid email/username or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end
end
