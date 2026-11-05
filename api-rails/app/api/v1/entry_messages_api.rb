module V1
  class EntryMessagesAPI < Grape::API
    helpers ::Helpers::AuthenticationHelper

    helpers do
      def chat_entry!
        entry = Entry.joins(:topic).find_by(id: params[:entry_id])
        error!({ message: 'Entry not found' }, 404) unless entry
        follow = current_user.topic_follows.find_by(topic_id: entry.topic_id)
        error!({ message: 'Entry not found' }, 404) unless follow
        error!({ message: 'Forbidden' }, 403) if follow.permissions.include?('banned')
        entry
      end

      def own_message!
        message = chat_entry!.entry_messages.find_by(id: params[:message_id])
        error!({ message: 'Message not found' }, 404) unless message
        error!({ message: 'Forbidden' }, 403) unless message.user_id == current_user.id
        message
      end

      def save_message!(message)
        return if message.save
        error!({ message: 'Invalid message', errors: message.errors.to_hash }, 422)
      end
    end

    before { current_user }

    resource :entries do
      route_param :entry_id, type: Integer do
        resource :messages do
          desc '지출별 대화 조회 (최신순, 이전 메시지 커서)'
          params do
            optional :before_id, type: Integer, values: 1..9_223_372_036_854_775_807
            optional :limit, type: Integer, default: 30, values: 1..100
          end
          get do
            scope = chat_entry!.entry_messages
            scope = scope.where('id < ?', params[:before_id]) if params[:before_id]
            records = scope.includes(:user).order(id: :desc).limit(params[:limit] + 1).to_a
            has_more = records.size > params[:limit]
            records = records.first(params[:limit])
            {
              records: Entities::EntryMessageEntity.represent(records).as_json,
              has_more: has_more,
              next_before_id: has_more ? records.last.id : nil
            }
          end

          desc '메시지 작성 (Piggy 구독자)'
          params do
            requires :body, type: String, allow_blank: false
          end
          post do
            message = chat_entry!.entry_messages.build(user: current_user, body: params[:body])
            save_message!(message)
            status 201
            present message, with: Entities::EntryMessageEntity
          end

          post :connection_ticket do
            entry = chat_entry!
            ticket = Rails.application.message_verifier(:chat_connection).generate(
              { user_id: current_user.id, entry_id: entry.id,
                token_digest: Digest::SHA256.hexdigest(current_user.token) },
              expires_in: 1.minute, purpose: :chat_connection
            )
            { ticket: ticket }
          end

          route_param :message_id, type: Integer do
            desc '본인 메시지 수정'
            params do
              requires :body, type: String, allow_blank: false
            end
            patch do
              message = own_message!
              message.body = params[:body]
              save_message!(message)
              present message, with: Entities::EntryMessageEntity
            end

            desc '본인 메시지 영구 삭제'
            delete do
              own_message!.destroy!
              status 204
              body false
            end
          end
        end
      end
    end
  end
end
