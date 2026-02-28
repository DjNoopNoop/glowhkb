class PasswordMailer < ApplicationMailer
  helper Rails.application.routes.url_helpers

  def password_reset(user)
    @user = user
    @site_name = Rails.application.class.module_parent_name rescue 'Site'
    # Use the raw reset_token generated and stored on user.reset_token by controller
    @token = user.reset_token
    @reset_url = edit_password_reset_url(@token, email: @user.email, host: default_host)

    mail(to: @user.email, subject: "#{@site_name}: Password reset instructions")
  end
end
