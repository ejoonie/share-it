module Entities
  class UserEntity < Grape::Entity
    expose :id
    expose :email
    expose :nick_name
    expose :token
    expose :created_at
    expose :updated_at
  end
end
