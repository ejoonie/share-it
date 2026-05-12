module Entities
  class TopicFollowEntity < Grape::Entity
    expose :id
    expose :user_id
    expose :topic_id
    expose :permissions
    expose :followed_at
    expose :invited_at
    expose :user do |topic_follow|
      {
        id: topic_follow.user.id,
        email: topic_follow.user.email,
        name: topic_follow.user.nick_name
      }
    end
  end
end
