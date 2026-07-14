class SesEmailService
  EMAIL_WHITELIST = ENV.fetch('EMAIL_WHITELIST', 'ejoonie@gmail.com').split(',').map(&:strip).freeze

  class << self
    def send_login_code(to:, code:)
      send_general(
        to: to,
        subject: "#{code} is your Sharable Piggy login code",
        body: <<~HTML,
          <p>Your login code is <strong>#{code}</strong>.</p>
          <p>It expires in 10 minutes. Do not share it with anyone.</p>
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
