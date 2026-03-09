class ApplicationMailer < ActionMailer::Base
  default from: "support@glowhkb.net"
  layout "mailer"
  # Expose helper methods to mailer views
  helper do
    # Returns the default host used for mailer URLs, falling back safely
    def default_host
      ado = Rails.application.config.action_mailer.default_url_options
      rdo = Rails.application.routes.respond_to?(:default_url_options) ? Rails.application.routes.default_url_options : nil
      host = (ado || rdo || {})[:host]
      host.presence || 'localhost:3000'
    end
  end
  
  # Also provide as an instance method so mailers can call `default_host`
  def default_host
    ado = Rails.application.config.action_mailer.default_url_options
    rdo = Rails.application.routes.respond_to?(:default_url_options) ? Rails.application.routes.default_url_options : nil
    host = (ado || rdo || {})[:host]
    host.presence || 'localhost:3000'
  end
end
