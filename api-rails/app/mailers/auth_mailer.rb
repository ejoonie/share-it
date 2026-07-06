class AuthMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'noreply@sharablepiggy.com')

  def send_otp(user, code)
    @user = user
    @code = code
    mail(to: user.email, subject: "#{code} is your Sharable Piggy login code")
  end
end
