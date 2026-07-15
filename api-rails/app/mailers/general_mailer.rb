class GeneralMailer < ApplicationMailer
  default from: ENV.fetch("SES_SENDER_EMAIL", "noreply@sharablepiggy.com")

  def send_mail(to:, subject:, body:, text_body: nil)
    @body = body
    @text_body = text_body

    mail(to: to, subject: subject) do |format|
      format.html { render plain: @body }
      format.text { render plain: @text_body || ActionView::Base.full_sanitizer.sanitize(@body) }
    end
  end
end
