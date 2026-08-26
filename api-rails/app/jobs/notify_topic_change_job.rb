# frozen_string_literal: true

# NotifyTopicChange가 위임한 실제 푸시 발송 잡.
class NotifyTopicChangeJob < ApplicationJob
  queue_as :default

  ACTION_VERBS = {
    "created" => "added",
    "updated" => "updated",
    "deleted" => "deleted",
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
    verb = ACTION_VERBS.fetch(action, "added")
    entry_label = entry.title.presence || "No title"
    body =
      if entry.amount.positive?
        "#{actor.nick_name} #{verb} #{format_amount(entry.amount)} for #{entry_label}"
      else
        "#{actor.nick_name} #{verb} #{entry_label}"
      end

    data = {
      type: "entry_change",
      topic_id: topic_id,
      entry_id: entry_id,
      occurred_at: occurred_at,
      action: action,
    }

    tokens.find_each do |device_token|
      response = FcmClient.send_message(token: device_token.token, title: title, body: body, data: data)
      handle_response(response, device_token)
    end
  end

  private

  # entry.amount는 센트 단위 정수(예: 4200 = $42.00)로 저장된다 - lib/models/expense_model.dart의
  # amountInDollars와 동일한 변환.
  def format_amount(cents)
    format("$%.2f", cents / 100.0)
  end

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
