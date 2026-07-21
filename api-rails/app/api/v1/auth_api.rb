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
      # POST /api/v1/auth/merge
      desc '게스트 계정을 실제 계정으로 병합. 현재 유저(게스트)의 데이터를 target_user_token 계정으로 이전한다.'
      params do
        requires :guest_token,  type: String, desc: '게스트 계정 토큰'
        requires :target_token, type: String, desc: '병합 대상 실제 계정 토큰'
      end
      post :merge do
        guest_user  = User.find_by(token: params[:guest_token])
        target_user = User.find_by(token: params[:target_token])

        error!({ message: 'Guest user not found.' }, 404)  unless guest_user
        error!({ message: 'Target user not found.' }, 404) unless target_user
        error!({ message: 'Guest user is not a guest account.' }, 422) unless guest_user.is_guest?
        error!({ message: 'Cannot merge into a guest account.' }, 422) if target_user.is_guest?

        guest_user.merge_into!(target_user)

        status 200
        { message: 'Merge completed.', user: Entities::UserEntity.represent(target_user) }
      end
    end
  end
end
