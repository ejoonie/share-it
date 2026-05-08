module Entities
  class TopicEntity < Grape::Entity
    expose :id
    expose :user_id
    expose :title
    expose :is_default
    expose :deleted_at
    expose :created_at
    expose :updated_at
  end
end
