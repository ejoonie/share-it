module V1
  module My
    class DeviceTokensAPI < Grape::API
      helpers ::Helpers::AuthenticationHelper

      resource :device_tokens do
        # POST /api/v1/my/device_tokens
        desc 'FCM 디바이스 토큰 등록/갱신 (로그인·앱 시작 시 호출)'
        params do
          requires :token, type: String, regexp: /\S/
          requires :platform, type: String, values: DeviceToken::PLATFORMS
        end
        post do
          device_token = DeviceToken.find_or_initialize_by(token: params[:token])
          device_token.user = current_user
          device_token.platform = params[:platform]
          device_token.last_seen_at = Time.current
          device_token.save!

          status 201
          { id: device_token.id }
        end

        # DELETE /api/v1/my/device_tokens/:token
        desc '디바이스 토큰 등록 해제 (로그아웃 시 호출)'
        delete ':token' do
          current_user.device_tokens.where(token: params[:token]).delete_all
          status 204
        end
      end
    end
  end
end
