module V1
  class GuestLoginAPI < Grape::API
    # POST /api/v1/guest_login
    desc '게스트 로그인'
    params do
      requires :firebase_token, type: String
    end
    post :guest_login do
      firebase_token = params[:firebase_token].strip

      uid = begin
        FirebaseTokenVerifier.new(firebase_token).verify!
      rescue FirebaseTokenVerifier::VerificationError => e
        existing = FirebaseToken.find_by(token: firebase_token)
        existing&.update!(last_failed_at: Time.current)
        error!({ message: e.message }, 401)
      end

      email = "#{uid}@example.com"

      user = User.find_by(email: email)

      if user.nil?
        nick_name = "Guest"
        user = User.create!(email: email, nick_name: nick_name)
      end

      FirebaseToken.find_or_create_by!(token: firebase_token) do |ft|
        ft.user = user
      end

      status 200
      present user, with: Entities::UserEntity
    end
  end
end
