begin
  require 'mailgun-ruby'
rescue LoadError
  Rails.logger.warn "mailgun-ruby gem not installed; Mailgun API delivery disabled"
else
  class MailgunApiDelivery
    def initialize(values)
      @api_key = (values && values[:api_key]) || ENV['MAILGUN_API_KEY']
      @domain  = (values && values[:domain])  || ENV['MAILGUN_DOMAIN'] || ENV['SMTP_DOMAIN']
      @client = Mailgun::Client.new(@api_key) if @api_key.present?
    end

    def deliver!(mail)
      raise "Mailgun API key missing" unless @client && @domain

      # Build message parameters
      params = {
        from:    mail.header[:from].to_s,
        to:      mail.header[:to].to_s,
        subject: mail.subject
      }

      # Mail gem supports both text and html parts
      if mail.multipart?
        parts = mail.parts
        html = parts.find { |p| p.content_type && p.content_type.include?('text/html') }
        text = parts.find { |p| p.content_type && p.content_type.include?('text/plain') }
        params[:html] = html.body.decoded if html
        params[:text] = text.body.decoded if text
      else
        body = mail.body.decoded
        # Heuristic: prefer html when content_type includes html
        if mail.content_type && mail.content_type.include?('html')
          params[:html] = body
        else
          params[:text] = body
        end
      end

      # Send via Mailgun API
      @client.send_message(@domain, params)
    end
  end

  ActionMailer::Base.add_delivery_method :mailgun_api, MailgunApiDelivery
end
