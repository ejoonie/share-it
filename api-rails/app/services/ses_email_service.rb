# frozen_string_literal: true

# Sends transactional emails via Amazon SES v2.
#
# Configuration is driven by environment variables:
#   AWS_REGION           — SES region (default: us-east-1)
#   AWS_ACCESS_KEY_ID    — AWS credentials (injected by IAM role in production)
#   AWS_SECRET_ACCESS_KEY
#   SES_SENDER_EMAIL     — verified sender address, e.g. noreply@sharablepiggy.com
class SesEmailService
  SENDER_EMAIL = ENV.fetch('SES_SENDER_EMAIL', 'noreply@sharablepiggy.com')

  class << self
    # Sends a login verification code to the given email address.
    #
    # @param to      [String] recipient email address
    # @param code    [String] 6-digit OTP
    def send_login_code(to:, code:)
      subject = '[Share It] Your login code'
      body_text = <<~TEXT
        Your login code is: #{code}

        This code expires in 10 minutes.
        If you did not request this, you can safely ignore this email.
      TEXT
      body_html = <<~HTML
        <p>Your Share It login code is:</p>
        <h2 style="letter-spacing:8px;">#{code}</h2>
        <p>This code expires in <strong>10 minutes</strong>.</p>
        <p style="color:#888;font-size:12px;">If you did not request this code, please ignore this email.</p>
      HTML

      send_email(to: to, subject: subject, body_text: body_text, body_html: body_html)
    end

    # Sends a password-change verification code to the given email address.
    #
    # @param to      [String] recipient email address
    # @param code    [String] 6-digit OTP
    def send_password_change_code(to:, code:)
      subject = '[Share It] Password change verification'
      body_text = <<~TEXT
        Your password change verification code is: #{code}

        This code expires in 10 minutes.
        If you did not request this, please secure your account immediately.
      TEXT
      body_html = <<~HTML
        <p>Your Share It password change verification code is:</p>
        <h2 style="letter-spacing:8px;">#{code}</h2>
        <p>This code expires in <strong>10 minutes</strong>.</p>
        <p style="color:#888;font-size:12px;">If you did not request this, please secure your account immediately.</p>
      HTML

      send_email(to: to, subject: subject, body_text: body_text, body_html: body_html)
    end

    private

    def client
      @client ||= Aws::SESV2::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1'))
    end

    def send_email(to:, subject:, body_text:, body_html:)
      client.send_email(
        from_email_address: SENDER_EMAIL,
        destination: { to_addresses: [to] },
        content: {
          simple: {
            subject: { data: subject, charset: 'UTF-8' },
            body: {
              text: { data: body_text, charset: 'UTF-8' },
              html: { data: body_html, charset: 'UTF-8' }
            }
          }
        }
      )
    end
  end
end
