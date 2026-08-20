# frozen_string_literal: true

require "googleauth"
require "net/http"
require "json"

# Firebase Cloud Messaging HTTP v1 API를 통해 push 메시지를 발송한다.
#
# 서비스 계정 키 파일이 필요하다 (레포에는 포함되지 않음, .gitignore 참고):
#   config/firebase/service_account.json
# 또는 FIREBASE_SERVICE_ACCOUNT_PATH 환경변수로 다른 경로를 지정할 수 있다.
#
# 키 파일이 없는 환경(다른 개발자 로컬, CI 등)에서도 앱이 죽지 않도록
# #configured? 로 미리 확인하고 쓰는 걸 전제로 한다 (NotifyTopicChangeJob 참고).
class FcmClient
  SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

  class << self
    def configured?
      File.exist?(service_account_path)
    end

    def send_message(token:, title:, body:, data: {})
      new.send_message(token: token, title: title, body: body, data: data)
    end

    def credentials
      @credentials ||= Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(service_account_path),
        scope: SCOPE
      )
    end

    def project_id
      @project_id ||= JSON.parse(File.read(service_account_path))["project_id"]
    end

    def service_account_path
      ENV.fetch("FIREBASE_SERVICE_ACCOUNT_PATH") { Rails.root.join("config/firebase/service_account.json").to_s }
    end
  end

  # @return [Net::HTTPResponse]
  def send_message(token:, title:, body:, data: {})
    uri = URI("https://fcm.googleapis.com/v1/projects/#{self.class.project_id}/messages:send")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"
    request.body = {
      message: {
        token: token,
        notification: { title: title, body: body },
        data: data.transform_values(&:to_s)
      }
    }.to_json

    http.request(request)
  end

  private

  def access_token
    creds = self.class.credentials
    creds.fetch_access_token! if creds.access_token.nil? || creds.expired?
    creds.access_token
  end
end
