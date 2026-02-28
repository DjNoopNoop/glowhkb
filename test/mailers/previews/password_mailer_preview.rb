class PasswordMailerPreview < ActionMailer::Preview
  def password_reset
    user = User.new(username: "Jane Doe", email: "jane@example.com")
    # Set a dummy token so the preview shows a working link
    user.reset_token = "dummytoken"
    PasswordMailer.password_reset(user)
  end
end
