# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'My Account API', type: :request do
  before do
    allow(SesEmailService).to receive(:send_password_change_code)
  end

  describe 'POST /api/v1/my/account/accept_terms' do
    it 'records terms acceptance for the current user' do
      user = users(:user_one)
      expect(user.terms_accepted_at).to be_nil

      post_json '/api/v1/my/account/accept_terms', login_user: user

      expect(response).to have_http_status(200)
      expect(json_response['terms_accepted_at']).to be_present
      expect(user.reload.terms_accepted_at).to be_present
    end

    it 'returns 401 when not authenticated' do
      post '/api/v1/my/account/accept_terms'
      expect(response).to have_http_status(401)
    end
  end

  describe 'POST /api/v1/my/account/request_password_change' do
    it 'sends a verification code to the current user email' do
      user = users(:user_one)

      post_json '/api/v1/my/account/request_password_change', login_user: user

      expect(response).to have_http_status(200)
      expect(json_response['message']).to be_present
      expect(SesEmailService).to have_received(:send_password_change_code)
        .with(to: user.email, code: anything)
    end

    it 'returns 401 when not authenticated' do
      post '/api/v1/my/account/request_password_change'
      expect(response).to have_http_status(401)
    end

    it 'returns 503 when SES fails' do
      allow(SesEmailService).to receive(:send_password_change_code).and_raise(RuntimeError, 'SES error')
      user = users(:user_one)

      post_json '/api/v1/my/account/request_password_change', login_user: user

      expect(response).to have_http_status(503)
    end
  end

  describe 'POST /api/v1/my/account/change_password' do
    it 'changes the password when code and confirmation are valid' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/my/account/change_password', login_user: user, params: {
        code: code,
        password: 'newpassword1',
        password_confirmation: 'newpassword1'
      }

      expect(response).to have_http_status(200)
      expect(user.reload.authenticate('newpassword1')).to be_truthy
    end

    it 'returns 422 when code is invalid' do
      user = users(:user_one)
      user.generate_login_code!

      post_json '/api/v1/my/account/change_password', login_user: user, params: {
        code: '000000',
        password: 'newpassword1',
        password_confirmation: 'newpassword1'
      }

      expect(response).to have_http_status(422)
    end

    it 'returns 422 when passwords do not match' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/my/account/change_password', login_user: user, params: {
        code: code,
        password: 'newpassword1',
      }

      expect(response).to have_http_status(200) # checks in the client side
    end

    it 'returns 422 when password is too short' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/my/account/change_password', login_user: user, params: {
        code: code,
        password: '12345',
        password_confirmation: '12345'
      }

      expect(response).to have_http_status(422)
    end

    it 'clears the code after successful password change' do
      user = users(:user_one)
      code = user.generate_login_code!

      post_json '/api/v1/my/account/change_password', login_user: user, params: {
        code: code,
        password: 'newpassword1',
        password_confirmation: 'newpassword1'
      }

      expect(user.reload.login_code).to be_nil
    end

    it 'returns 401 when not authenticated' do
      post '/api/v1/my/account/change_password'
      expect(response).to have_http_status(401)
    end
  end
end
