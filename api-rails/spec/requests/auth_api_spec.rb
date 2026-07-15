# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth API', type: :request do
  before do
    allow(SesEmailService).to receive(:send_login_code)
    allow(SesEmailService).to receive(:send_password_change_code)
  end

  describe 'POST /api/v1/auth/request_login_code' do
    it 'sends a code to an existing user' do
      user = users(:user_one)

      post_json '/api/v1/auth/request_login_code', params: { email: user.email }

      expect(response).to have_http_status(200)
      expect(json_response['message']).to be_present
      expect(SesEmailService).to have_received(:send_login_code).with(to: user.email, code: anything)
    end

    it 'creates a new user and sends a code when the email is unknown' do
      expect {
        post_json '/api/v1/auth/request_login_code', params: { email: 'newuser@example.com' }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(200)
      expect(SesEmailService).to have_received(:send_login_code).with(to: 'newuser@example.com', code: anything)
    end

    it 'returns 400 for an invalid email format' do
      post_json '/api/v1/auth/request_login_code', params: { email: 'not-an-email' }

      expect(response).to have_http_status(400)
    end

    it 'returns 503 when SES fails' do
      allow(SesEmailService).to receive(:send_login_code).and_raise(RuntimeError, 'SES error')

      post_json '/api/v1/auth/request_login_code', params: { email: users(:user_one).email }

      expect(response).to have_http_status(503)
    end
  end

  describe 'POST /api/v1/auth/verify_login_code' do
    it 'returns a token when the code is valid' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: code }

      expect(response).to have_http_status(200)
      expect(json_response['user']['token']).to eq(user.token)
      expect(json_response['is_new_user']).to be(false).or be(true)
    end

    it 'sets is_new_user true when terms have not been accepted' do
      user = users(:user_one)
      user.update!(terms_accepted_at: nil)
      code = user.generate_login_code!

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: code }

      expect(response).to have_http_status(200)
      expect(json_response['is_new_user']).to eq(true)
    end

    it 'sets is_new_user false when terms have been accepted' do
      user = users(:user_one)
      user.update!(terms_accepted_at: Time.current)
      code = user.generate_login_code!

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: code }

      expect(response).to have_http_status(200)
      expect(json_response['is_new_user']).to eq(false)
    end

    it 'returns 422 for an incorrect code' do
      user = users(:user_one)
      user.generate_login_code!

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: '000000' }

      expect(response).to have_http_status(422)
    end

    it 'returns 422 for an expired code' do
      user = users(:user_one)
      user.generate_login_code!
      user.update_columns(login_code_expires_at: 1.minute.ago)

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: user.login_code }

      expect(response).to have_http_status(422)
    end

    it 'clears the code after successful verification' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/auth/verify_login_code', params: { email: user.email, code: code }

      expect(user.reload.login_code).to be_nil
    end
  end

  describe 'POST /api/v1/auth/login' do
    it 'returns a token for correct credentials' do
      user = users(:user_one)
      user.update!(password: 'password123')

      post_json '/api/v1/auth/login', params: { email: user.email, password: 'password123' }

      expect(response).to have_http_status(200)
      expect(json_response['user']['token']).to eq(user.token)
    end

    it 'returns 401 for wrong password' do
      user = users(:user_one)
      user.update!(password: 'password123')

      post_json '/api/v1/auth/login', params: { email: user.email, password: 'wrongpassword' }

      expect(response).to have_http_status(401)
    end

    it 'returns 401 when user has no password set' do
      user = users(:user_one)

      post_json '/api/v1/auth/login', params: { email: user.email, password: 'anything' }

      expect(response).to have_http_status(401)
    end

    it 'returns 401 for unknown email' do
      post_json '/api/v1/auth/login', params: { email: 'nobody@example.com', password: 'password' }

      expect(response).to have_http_status(401)
    end
  end
end
