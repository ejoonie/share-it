# frozen_string_literal: true

# entry가 생성/수정/삭제될 때, 같은 토픽을 구독 중인 다른 유저들에게 푸시 알림을
# 보낼 대상을 추려서 NotifyTopicChangeJob에 위임한다 (이슈 #116).
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
    recipient_follows.find_each do |follow|
      device_token_ids = follow.user.device_tokens.pluck(:id)
      next if device_token_ids.empty?

      NotifyTopicChangeJob.perform_later(
        device_token_ids: device_token_ids,
        topic_id: @entry.topic_id,
        entry_id: @entry.id,
        actor_id: @actor.id,
        occurred_at: @entry.occurred_at&.iso8601,
        action: @action.to_s
      )
    end
  end

  private

  def recipient_follows
    TopicFollow
      .where(topic_id: @entry.topic_id, notifications_enabled: true)
      .where.not(user_id: @actor.id)
      .includes(:user)
  end
end
