# frozen_string_literal: true

# NotifyTopicChange가 위임한 실제 푸시 발송 잡.
#
# TODO(#116): Firebase 프로젝트/서비스 계정 키가 준비되면 FcmClient(가칭)로
# HTTP v1 API(https://fcm.googleapis.com/v1/projects/{project}/messages:send)에
# 실제로 발송하는 코드로 교체한다. 그때까지는 로그만 남긴다.
class NotifyTopicChangeJob < ApplicationJob
  queue_as :default

  def perform(device_token_ids:, topic_id:, entry_id:, occurred_at:, action:)
    tokens = DeviceToken.where(id: device_token_ids).pluck(:token)
    return if tokens.empty?

    Rails.logger.info(
      "[push] (stub) topic=#{topic_id} entry=#{entry_id} action=#{action} " \
      "occurred_at=#{occurred_at} tokens=#{tokens.size}"
    )
  end
end
