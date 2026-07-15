# frozen_string_literal: true

module V1
  module My
    class AccountAPI < Grape::API
      helpers ::Helpers::AuthenticationHelper

      before { current_user }

      resource :account do
        # POST /api/v1/my/account/accept_terms
        desc '서비스 이용 약관 동의'
        post :accept_terms do
          current_user.update!(terms_accepted_at: Time.current)

          status 200
          present current_user, with: Entities::UserEntity
        end

        # POST /api/v1/my/account/request_password_change
        desc '비밀번호 변경을 위한 이메일 인증 코드 전송'
        post :request_password_change do
          code = current_user.generate_login_code!

          begin
            SesEmailService.send_password_change_code(to: current_user.email, code: code)
          rescue => e
            Rails.logger.error("SES send failed for #{current_user.email}: #{e.message}")
            error!({ message: 'Failed to send email. Please try again.' }, 503)
          end

          status 200
          { message: 'Verification code sent to your email.' }
        end

        # POST /api/v1/my/account/merge_guest
        desc '게스트 계정의 토픽을 현재 계정으로 이전 후 게스트 계정 삭제'
        params do
          requires :guest_token, type: String
        end
        post :merge_guest do
          guest = User.find_by(token: params[:guest_token], is_guest: true)
          error!({ message: 'Guest data not found.' }, 404) unless guest

          begin
            ActiveRecord::Base.transaction do
              guest.topics.update_all(user_id: current_user.id)
              guest.topic_follows.update_all(user_id: current_user.id)
              Entry.where(created_by_id: guest.id).update_all(created_by_id: current_user.id)
              Entry.where(updated_by_id: guest.id).update_all(updated_by_id: current_user.id)
              guest.destroy!
            end
          rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotDestroyed => e
            error!({ message: 'Failed to merge guest data.' }, 500)
          end

          status 200
          { message: 'Guest data merged successfully.' }
        end

        # POST /api/v1/my/account/change_password
        desc '비밀번호 변경 (이메일 코드 검증 후 신규 패스워드 설정)'
        params do
          requires :code,     type: String, regexp: /\A\d{6}\z/
          requires :password, type: String
        end
        post :change_password do
          error!({ message: 'Invalid or expired code.' }, 422) unless current_user.valid_login_code?(params[:code])
          error!({ message: 'Password must be at least 6 characters.' }, 422) if params[:password].length < 6

          current_user.consume_login_code!
          current_user.update!(password: params[:password])

          status 200
          present current_user, with: Entities::UserEntity
        end
      end
    end
  end
end
