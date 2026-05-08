module Entities
  class TopicEntity < Grape::Entity
    expose :id
    expose :owner_id
    expose :title
    expose :is_default
    expose :created_at
    expose :updated_at
  end
end
