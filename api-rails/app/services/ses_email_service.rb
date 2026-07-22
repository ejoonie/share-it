# frozen_string_literal: true

# Sends transactional emails via Amazon SES SMTP through ActionMailer.
#
# Required environment variables:
#   SMTP_USERNAME    — SES SMTP user name (looks like an access key: AKIA…)
#   SMTP_PASSWORD    — SES SMTP password
#   SES_SENDER_EMAIL — verified sender address, e.g. noreply@sharablepiggy.com
#
# Non-production behaviour:
#   - Emails are only delivered to addresses listed in EMAIL_WHITELIST
class SesEmailService
  EMAIL_WHITELIST = %w[ejoonie@gmail.com ejoonie.a@gmail.com].freeze

  class << self
    def send_login_code(to:, code:)
      send_general(
        to: to,
        subject: "#{code} is your Sharable Piggy login code",
        body: <<~HTML,
          <p>Your Piggy login code is:</p>
          <h2 style="letter-spacing:8px;">#{code}</h2>
          <p>This code expires in <strong>10 minutes</strong>.</p>
          <p style="color:#888;font-size:12px;">If you did not request this code, please ignore this email.</p>
        HTML
      )
    end

    def send_password_change_code(to:, code:)
      send_general(
        to: to,
        subject: "#{code} is your Sharable Piggy password change code",
        body: <<~HTML,
          <p>Your Piggy password change verification code is:</p>
          <h2 style="letter-spacing:8px;">#{code}</h2>
          <p>This code expires in <strong>10 minutes</strong>.</p>
          <p style="color:#888;font-size:12px;">If you did not request this, please secure your account immediately.</p>
        HTML
      )
    end

    def send_general(to:, subject:, body:)
      return unless deliverable?(to)

      GeneralMailer.send_mail(to: to, subject: subject, body: body).deliver_now
    end

    private

    def deliverable?(email)
      Rails.env.production? || EMAIL_WHITELIST.include?(email)
    end
  end
end
