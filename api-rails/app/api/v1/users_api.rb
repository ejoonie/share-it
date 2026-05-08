module V1
  class UsersAPI < Grape::API
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
