require 'rails_helper'

RSpec.describe SesEmailService do
  let(:delivery) { double(deliver_now: true) }

  it 'sends login codes in an email OTP friendly HTML and text format' do
    expect(GeneralMailer).to receive(:send_mail).with(
      to: 'ejoonie@gmail.com',
      subject: '123456 is your Sharable Piggy login code',
      body: a_string_including('<strong>123456</strong> is your verification code'),
      text_body: a_string_starting_with('123456 is your verification code')
    ).and_return(delivery)

    described_class.send_login_code(to: 'ejoonie@gmail.com', code: '123456')
  end

  it 'sends password-change codes in the same OTP friendly format' do
    expect(GeneralMailer).to receive(:send_mail).with(
      to: 'ejoonie@gmail.com',
      subject: '654321 is your Sharable Piggy password change code',
      body: a_string_including('<strong>654321</strong> is your verification code'),
      text_body: a_string_starting_with('654321 is your verification code')
    ).and_return(delivery)

    described_class.send_password_change_code(to: 'ejoonie@gmail.com', code: '654321')
  end
end
