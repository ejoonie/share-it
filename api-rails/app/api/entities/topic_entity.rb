module Entities
  class TopicEntity < Grape::Entity
    expose :id
    expose :token
    expose :user_id
    expose :title
    expose :is_default
    expose :default_permissions
    expose :deleted_at
    expose :created_at
    expose :updated_at
  end
end
