# frozen_string_literal: true

# entry가 생성/수정/삭제될 때, 같은 토픽을 구독 중인 다른 유저들에게 푸시 알림을
# 보낼 대상을 추려서 SendPushJob에 위임한다 (이슈 #116).
#
# - 변경을 만든 본인(actor)은 제외한다.
# - 해당 구독(TopicFollow)의 notifications_enabled가 꺼져 있으면 제외한다
#   (읽음/안읽음 표시는 이 설정과 무관하게 항상 동작 — entries_api.rb 참고).
class NotifyTopicChange
  class << self
    def call(entry:, actor:, action:)
      new(entry: entry, actor: actor, action: action).call
    end
  end

  def initialize(entry:, actor:, action:)
    @entry = entry
    @actor = actor
    @action = action # :created | :updated | :deleted
  end

  def call
    message = PushMessage.for_entry_change(
      entry: @entry,
      topic: @entry.topic,
      actor: @actor,
      action: @action,
      occurred_at: @entry.occurred_at&.iso8601
    )

    recipient_tokens.find_each do |device_token|
      SendPushJob.perform_later(
        device_token_id: device_token.id,
        title: message.title,
        body: message.body,
        data: message.data
      )
    end
  end

  private

  def recipient_tokens
    DeviceToken
      .joins(user: :topic_follows)
      .where(
        topic_follows: {
          topic_id: @entry.topic_id,
          notifications_enabled: true
        },
        users: { notifications_enabled: true }
      )
      .where.not(device_tokens: { user_id: @actor.id })
      .distinct
  end
end
