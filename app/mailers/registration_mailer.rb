class RegistrationMailer < ApplicationMailer
  helper Rails.application.routes.url_helpers

  def registrant_pending(user)
    @user = user
    @site_name = Rails.application.class.module_parent_name rescue 'Site'
    mail(to: @user.email, subject: "#{@site_name}: Registration received — awaiting approval")
  end

  def admin_notification(admin, user)
    @admin = admin
    @user = user
    @admin_url = admin_registrants_url(host: default_host)

    mail(to: @admin.email, subject: "New user awaiting approval: #{@user.email}")
  end

  def approved(user)
    @user = user
    @site_name = Rails.application.class.module_parent_name rescue 'Site'
    @sign_in_url = login_url(host: default_host)

    mail(to: @user.email, subject: "#{@site_name}: Your account is now active")
  end

  def denied(user)
    @user = user
    @site_name = Rails.application.class.module_parent_name rescue 'Site'
    @contact_url = root_url(host: default_host)

    mail(to: @user.email, subject: "#{@site_name}: Registration request declined")
  end
end
