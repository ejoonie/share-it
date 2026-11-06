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
          <p><strong>#{code}</strong> is your verification code for Sharable Piggy.</p>
          <p style="font-size:28px;font-weight:700;letter-spacing:8px;">#{code}</p>
          <p>This code expires in <strong>10 minutes</strong>.</p>
          <p style="color:#888;font-size:12px;">If you did not request this code, please ignore this email.</p>
        HTML
        text_body: <<~TEXT
          #{code} is your verification code for Sharable Piggy.

          This code expires in 10 minutes.
          If you did not request this code, please ignore this email.
        TEXT
      )
    end

    def send_password_change_code(to:, code:)
      send_general(
        to: to,
        subject: "#{code} is your Sharable Piggy password change code",
        body: <<~HTML,
          <p><strong>#{code}</strong> is your verification code for Sharable Piggy.</p>
          <p style="font-size:28px;font-weight:700;letter-spacing:8px;">#{code}</p>
          <p>This code expires in <strong>10 minutes</strong>.</p>
          <p style="color:#888;font-size:12px;">If you did not request this, please secure your account immediately.</p>
        HTML
        text_body: <<~TEXT
          #{code} is your verification code for Sharable Piggy.

          This code expires in 10 minutes.
          If you did not request this, please secure your account immediately.
        TEXT
      )
    end

    def send_general(to:, subject:, body:, text_body: nil)
      return unless deliverable?(to)

      GeneralMailer
        .send_mail(to: to, subject: subject, body: body, text_body: text_body)
        .deliver_now
    end

    private

    def deliverable?(email)
      Rails.env.production? || EMAIL_WHITELIST.include?(email)
    end
  end
end
