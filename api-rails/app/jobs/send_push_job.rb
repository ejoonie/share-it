# frozen_string_literal: true

class SendPushJob < ApplicationJob
  class PushDeliveryError < StandardError
    attr_reader :retry_after

    def initialize(message, retry_after: nil)
      super(message)
      @retry_after = retry_after
    end
  end

  queue_as :default
  rescue_from PushDeliveryError do |error|
    if executions < 3
      retry_job(wait: error.retry_after || polynomial_retry_delay)
    else
      Rails.logger.error("[push] retries exhausted: #{error.message}")
    end
  end

  def perform(device_token_id:, title:, body:, data:)
    unless FcmClient.configured?
      Rails.logger.warn("[push] Firebase service account not configured; skipping device_token_id=#{device_token_id}")
      return
    end

    device_token = DeviceToken.find_by(id: device_token_id)
    return if device_token.nil?

    result = FcmClient.send_message(
      token: device_token.token,
      title: title,
      body: body,
      data: data
    )

    case result
    when FcmClient::Success
      nil
    when FcmClient::InvalidToken
      device_token.destroy!
    when FcmClient::RetryableError
      raise PushDeliveryError.new(
        retryable_error_message(result, device_token),
        retry_after: result.retry_after
      )
    when FcmClient::PermanentError
      Rails.logger.error(
        "[push] permanent FCM failure device_token_id=#{device_token.id} " \
        "status=#{result.response&.code} body=#{result.response&.body}"
      )
    else
      raise "Unexpected FCM result: #{result.class}"
    end
  end

  private

  def retryable_error_message(result, device_token)
    detail = result.error&.message || "status=#{result.response&.code}"
    "FCM delivery failed device_token_id=#{device_token.id} #{detail} retry_after=#{result.retry_after}"
  end

  def polynomial_retry_delay
    executions**4 + (Kernel.rand * executions**4) + 2
  end
end
