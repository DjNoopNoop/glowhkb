class RecaptchaVerifier
  VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify"

  def self.enabled?
    ENV["RECAPTCHA_SECRET_KEY"].present?
  end

  # Returns true when the widget response token is valid, or when
  # reCAPTCHA is not configured (RECAPTCHA_SECRET_KEY unset).
  def self.verify(response_token, remote_ip: nil)
    return true unless enabled?
    return false if response_token.blank?

    params = { secret: ENV["RECAPTCHA_SECRET_KEY"], response: response_token, remoteip: remote_ip }.compact
    body = Faraday.post(VERIFY_URL, URI.encode_www_form(params), "Content-Type" => "application/x-www-form-urlencoded").body
    JSON.parse(body)["success"] == true
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error "reCAPTCHA verification failed: #{e.message}"
    false
  end
end
