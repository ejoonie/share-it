# frozen_string_literal: true

module V1
  class AuthAPI < Grape::API
    resource :auth do
      # POST /api/v1/auth/check_email
      desc '이메일로 신규 여부 및 패스워드 설정 여부를 확인'
      params do
        requires :email, type: String, regexp: /\A[^@\s]+@[^@\s]+\z/
      end
      post :check_email do
        user = User.find_by(email: params[:email].strip.downcase)
        if user.nil?
          { is_new_user: true, has_password: false }
        else
          { is_new_user: false, has_password: user.password_digest.present? }
        end
      end

      # POST /api/v1/auth/request_login_code
      desc '이메일로 로그인 코드(OTP) 전송'
      params do
        requires :email, type: String, regexp: /\A[^@\s]+@[^@\s]+\z/
      end
      post :request_login_code do
        email = params[:email].strip.downcase

        user = User.find_by(email: email)
        if user.nil?
          nick_name = "User-#{SecureRandom.hex(4)}"
          user = User.create!(email: email, nick_name: nick_name, is_guest: false)
        end

        code = user.generate_login_code!

        begin
          SesEmailService.send_login_code(to: email, code: code)
        rescue => e
          Rails.logger.error("SES send failed for #{email}: #{e.message}")
          error!({ message: 'Failed to send email. Please try again.' }, 503)
        end

        status 200
        { message: 'Verification code sent to your email.' }
      end

      # POST /api/v1/auth/verify_login_code
      desc '이메일 로그인 코드 검증 후 인증 토큰 발급'
      params do
        requires :email, type: String, regexp: /\A[^@\s]+@[^@\s]+\z/
        requires :code,  type: String, regexp: /\A\d{6}\z/
      end
      post :verify_login_code do
        email = params[:email].strip.downcase
        code  = params[:code].strip

        user = User.find_by(email: email)
        error!({ message: 'Invalid or expired code.' }, 422) unless user&.valid_login_code?(code)

        user.consume_login_code!

        is_new_user = !user.terms_accepted?

        status 200
        {
          user: Entities::UserEntity.represent(user),
          is_new_user: is_new_user
        }
      end

      # POST /api/v1/auth/login
      desc '이메일 + 패스워드로 로그인'
      params do
        requires :email,    type: String, regexp: /\A[^@\s]+@[^@\s]+\z/
        requires :password, type: String
      end
      post :login do
        email = params[:email].strip.downcase

        user = User.find_by(email: email)
        error!({ message: 'Invalid email or password.' }, 401) unless user&.authenticate(params[:password])

        is_new_user = !user.terms_accepted?

        status 200
        {
          user: Entities::UserEntity.represent(user),
          is_new_user: is_new_user
        }
      end
    end
  end
end
