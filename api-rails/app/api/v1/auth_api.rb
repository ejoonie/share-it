module V1
  class AuthAPI < Grape::API
    helpers ::Helpers::AuthenticationHelper

    resource :auth do
      # POST /api/v1/auth/check_email
      # 이메일로 신규 여부 및 패스워드 설정 여부를 반환한다.
      desc 'Check whether an email is new or existing, and if a password is set'
      params do
        requires :email, type: String, desc: 'Email address'
      end
      post :check_email do
        user = User.find_by(email: params[:email].downcase.strip)
        if user.nil?
          { is_new_user: true, has_password: false }
        else
          { is_new_user: false, has_password: user.password_digest.present? }
        end
      end

      # POST /api/v1/auth/request_login_code
      # OTP 코드를 발송한다. 신규 유저면 약관 동의 후 호출해야 한다.
      desc 'Send a one-time login code to the given email'
      params do
        requires :email, type: String, desc: 'Email address'
      end
      post :request_login_code do
        email = params[:email].downcase.strip
        user = User.find_or_initialize_by(email: email)
        if user.new_record?
          user.nick_name = email.split('@').first
          user.is_guest = false
          user.save!
        end

        code = user.generate_login_code!
        SesEmailService.send_login_code(to: email, code: code)

        { message: 'Login code sent' }
      end

      # POST /api/v1/auth/verify_login_code
      # OTP 코드를 검증하고 성공 시 유저와 토큰을 반환한다.
      desc 'Verify the one-time login code'
      params do
        requires :email, type: String, desc: 'Email address'
        requires :code,  type: String, desc: 'One-time code'
      end
      post :verify_login_code do
        user = User.find_by(email: params[:email].downcase.strip)
        error!({ message: 'Invalid or expired code' }, 422) unless user&.valid_login_code?(params[:code])

        user.consume_login_code!
        is_new_user = !user.terms_accepted?
        user.accept_terms! if is_new_user

        present({
          user: Entities::UserEntity.represent(user),
          is_new_user: is_new_user,
        })
      end

      # POST /api/v1/auth/login
      # 이메일 + 패스워드로 로그인한다.
      desc 'Login with email and password'
      params do
        requires :email,    type: String, desc: 'Email address'
        requires :password, type: String, desc: 'Password'
      end
      post :login do
        user = User.find_by(email: params[:email].downcase.strip)
        error!({ message: 'Invalid email or password' }, 422) unless user&.authenticate(params[:password])

        present({
          user: Entities::UserEntity.represent(user),
          is_new_user: false,
        })
      end
    end
  end
end
