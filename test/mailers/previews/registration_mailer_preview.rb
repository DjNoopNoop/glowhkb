# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  def registrant_pending
    user = User.new(name: 'New Registrant', email: 'new@example.com')
    RegistrationMailer.registrant_pending(user)
  end

  def admin_notification
    admin = User.new(name: 'Site Admin', email: 'admin@example.com')
    user = User.new(name: 'Pending User', email: 'pending@example.com', role: User::CONTRIBUTOR)
    RegistrationMailer.admin_notification(admin, user)
  end
end
