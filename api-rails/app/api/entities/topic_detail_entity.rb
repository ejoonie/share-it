module Entities
  class TopicDetailEntity < TopicEntity
    expose :owner_name do |topic|
      topic.user.nick_name
    end
    expose :is_owner do |topic, options|
      topic.user_id == options[:viewer].id
    end
    expose :followed_at do |_topic, options|
      options[:follow]&.followed_at
    end
  end
end
