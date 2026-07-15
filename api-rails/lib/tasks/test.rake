task email: :environment do
  # SesEmailService.send_general(
  #   to: "ejoonie@gmail.com",
  #   subject: "Test Email",
  #   body: "This is a test email.",
  #   )
  # SesEmailService.send_login_code(
  #   to: "ejoonie@gmail.com",
  #   code: "123456",
  #   )
  SesEmailService.send_password_change_code(
    to: "ejoonie@gmail.com",
    code: "123456",
  )
end
