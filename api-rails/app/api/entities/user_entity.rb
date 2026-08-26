module Entities
  class UserEntity < Grape::Entity
    expose :id
    expose :email
    expose :nick_name
    expose :is_guest
    expose :notifications_enabled
    expose :token
    expose :terms_accepted_at
    expose :created_at
    expose :updated_at
  end
end
