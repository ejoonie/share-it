module V1
  class AuthAPI < Grape::API
    resource :auth do
      # POST /api/v1/auth/send_code
      desc 'OTP 코드 발송 (계정 없으면 자동 생성)'
      params do
        requires :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP
      end
      post :send_code do
        email = params[:email].strip.downcase
        user = User.find_or_initialize_by(email: email)
        if user.new_record?
          user.nick_name = email.split('@').first
          user.save!
        end
        code = user.generate_otp!
        AuthMailer.send_otp(user, code).deliver_later
        { message: 'Code sent' }
      end

      # POST /api/v1/auth/verify_code
      desc 'OTP 코드 검증 후 토큰 반환'
      params do
        requires :email, type: String
        requires :code, type: String
      end
      post :verify_code do
        email = params[:email].strip.downcase
        user = User.find_by(email: email)
        error!({ message: 'User not found' }, 404) unless user
        error!({ message: 'Invalid or expired code' }, 422) unless user.verify_otp!(params[:code])
        present user, with: Entities::UserEntity
      end

      # POST /api/v1/auth/login
      desc '비밀번호로 로그인'
      params do
        requires :email, type: String
        requires :password, type: String
      end
      post :login do
        email = params[:email].strip.downcase
        user = User.find_by(email: email)
        error!({ message: 'Invalid credentials' }, 401) unless user&.authenticate(params[:password])
        present user, with: Entities::UserEntity
      end
    end
  end
end
