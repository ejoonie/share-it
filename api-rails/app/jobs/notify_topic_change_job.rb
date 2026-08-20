# frozen_string_literal: true

# NotifyTopicChange가 위임한 실제 푸시 발송 잡.
class NotifyTopicChangeJob < ApplicationJob
  queue_as :default

  ACTION_VERBS = {
    "created" => "새 기록을 추가했어요",
    "updated" => "기록을 수정했어요",
    "deleted" => "기록을 삭제했어요"
  }.freeze

  # 발송 실패로 봐서 디바이스 토큰을 지워도 되는 FCM 에러 코드
  UNREGISTERED_ERROR_CODES = %w[UNREGISTERED INVALID_ARGUMENT].freeze

  def perform(device_token_ids:, topic_id:, entry_id:, actor_id:, occurred_at:, action:)
    unless FcmClient.configured?
      Rails.logger.warn("[push] Firebase service account not configured; skipping (topic=#{topic_id} entry=#{entry_id})")
      return
    end

    tokens = DeviceToken.where(id: device_token_ids)
    return if tokens.none?

    topic = Topic.unscoped.find_by(id: topic_id)
    entry = Entry.unscoped.find_by(id: entry_id)
    actor = User.find_by(id: actor_id)
    return if topic.nil? || entry.nil? || actor.nil?

    title = topic.title
    verb = ACTION_VERBS.fetch(action, "기록을 변경했어요")
    body = "#{actor.nick_name}님이 #{verb}#{entry.title.presence ? ": #{entry.title}" : ''}"

    data = {
      type: "entry_change",
      topic_id: topic_id,
      entry_id: entry_id,
      occurred_at: occurred_at,
      action: action
    }

    tokens.find_each do |device_token|
      response = FcmClient.send_message(token: device_token.token, title: title, body: body, data: data)
      handle_response(response, device_token)
    end
  end

  private

  def handle_response(response, device_token)
    return if response.is_a?(Net::HTTPSuccess)

    error_codes =
      begin
        JSON.parse(response.body).dig("error", "details")&.filter_map { |d| d["errorCode"] } || []
      rescue JSON::ParserError
        []
      end

    if (error_codes & UNREGISTERED_ERROR_CODES).any?
      device_token.destroy
    else
      Rails.logger.error(
        "[push] FCM send failed device_token_id=#{device_token.id} status=#{response.code} body=#{response.body}"
      )
    end
  end
end
