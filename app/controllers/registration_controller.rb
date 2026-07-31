class RegistrationController < ApplicationController
  REGISTRATIONS_OPEN = true

  before_action :check_registrations_open, only: [:new, :create]

  def new
    @user = User.new
    render 'registration/new'
  end

  def create
    permitted = sanitize_role(user_params)
    @user = User.new(permitted)

    unless RecaptchaVerifier.verify(params["g-recaptcha-response"], remote_ip: request.remote_ip)
      @user.errors.add(:base, "Please complete the CAPTCHA to verify you're not a robot.")
      return render 'registration/new', status: :unprocessable_entity
    end

    if @user.save
      # send emails: to registrant and to site admins
      begin
        RegistrationMailer.registrant_pending(@user).deliver_later
        User.administrators.find_each do |admin|
          RegistrationMailer.admin_notification(admin, @user).deliver_later
        end
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue registration emails: #{e.message}"
      end

      redirect_to signup_pending_path, notice: 'Account created. Your account is pending admin approval.'
    else
      render 'registration/new', status: :unprocessable_entity
    end
  end

  def pending; end

  private

  def check_registrations_open
    unless REGISTRATIONS_OPEN
      redirect_to root_path, alert: 'Registrations are currently closed.'
    end
  end

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :role)
  end

  def sanitize_role(permitted_params)
    rp = permitted_params.to_h
    rp[:role] = User.public_roles.include?(rp[:role]) ? rp[:role] : User::CONTRIBUTOR
    rp
  end
end
