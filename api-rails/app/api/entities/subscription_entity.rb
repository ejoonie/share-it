module Entities
  # TopicFollow 레코드를 구독 정보로 표현한다.
  # topic 정보와 notifications_enabled를 함께 노출한다.
  class SubscriptionEntity < Grape::Entity
    expose :notifications_enabled
    expose :topic, using: Entities::TopicEntity
  end
end
