class PasswordMailer < ApplicationMailer
  helper Rails.application.routes.url_helpers

  def password_reset(user, token = nil)
    @user = user
    @site_name = Rails.application.class.module_parent_name rescue 'Site'
    # Prefer explicit token passed in (survives deliver_later), fall back to virtual attr
    @token = token || user.reset_token
    @reset_url = edit_password_reset_url(@token, email: @user.email, host: default_host)

    mail(to: @user.email, subject: "#{@site_name}: Password reset instructions")
  end
end
