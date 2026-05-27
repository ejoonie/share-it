module V1
  class UsersAPI < Grape::API
    resource :guest_login do
      # POST /api/v1/guest_login
      desc '게스트 로그인'
      params do
        requires :guest_token, type: String, regexp: /\S/
      end
      post do
        guest_token = params[:guest_token].strip
        email = "#{guest_token}@example.com"

        error!({ message: 'Guest already registered' }, 409) if User.exists?(email: email)

        user = User.create!(email: email, nick_name: 'Guest', is_guest: true)

        status 201
        present user, with: Entities::UserEntity
      end
    end

    resource :users do
      # POST /api/v1/users
      desc '유저 생성'
      params do
        requires :email, type: String, regexp: /\S/
        requires :nick_name, type: String, regexp: /\S/
      end
      post do
        email = params[:email].strip
        nick_name = params[:nick_name].strip

        user = User.create!(email: email, nick_name: nick_name)

        status 201
        present user, with: Entities::UserEntity
      end
    end
  end
end
