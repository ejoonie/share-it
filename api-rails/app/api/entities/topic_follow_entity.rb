module Entities
  class TopicFollowEntity < Grape::Entity
    expose :id
    expose :user_id
    expose :topic_id
    expose :permissions
    expose :followed_at
    expose :invited_at
    expose :user, using: Entities::UserEntity
  end
end
