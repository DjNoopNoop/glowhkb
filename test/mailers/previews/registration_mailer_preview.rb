class RegistrationMailerPreview < ActionMailer::Preview
  # Preview for the registrant_pending email
  def registrant_pending
    user = User.new(username: "Jane Doe", email: "jane@example.com")
    RegistrationMailer.registrant_pending(user)
  end

  # Preview for the admin notification email sent to administrators
  def admin_notification
    admin = User.new(username: "Site Admin", email: "admin@example.com", role: User::ADMINISTRATOR)
    user = User.new(username: "Jane Doe", email: "jane@example.com")
    RegistrationMailer.admin_notification(admin, user)
  end

  # Preview for the approved email
  def approved
    user = User.new(username: "Jane Doe", email: "jane@example.com")
    RegistrationMailer.approved(user)
  end

  # Preview for the denied email
  def denied
    user = User.new(username: "Jane Doe", email: "jane@example.com")
    RegistrationMailer.denied(user)
  end
end