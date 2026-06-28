module V1
  module My
    class TopicsAPI < Grape::API
      helpers ::Helpers::AuthenticationHelper

      helpers do
        def find_my_topic!
          topic = current_user&.topics&.find_by(id: params[:id])
          error!({ message: 'Topic not found' }, 404) if topic.nil?
          topic
        end
      end

      resource :topics do
        # POST /api/v1/my/topics
        desc '내 토픽 생성'
        params do
          requires :title, type: String, regexp: /\S/
        end
        post do
          title = params[:title].strip
          topic = current_user.topics.create!(
            user: current_user,
            title: title,
            is_default: false
          )

          status 201
          present topic, with: Entities::TopicEntity
        end

        # GET /api/v1/my/topics/owned
        desc '내가 생성한 토픽 목록'
        get :owned do
          paginated_list(current_user.topics, Entities::TopicEntity)
        end

        # GET /api/v1/my/topics/subscribed
        desc '내가 구독하는 토픽'
        get :subscribed do
          paginated_list(current_user.subscribed_topics, Entities::TopicEntity)
        end

        # DELETE /api/v1/my/topics/subscribed/:id
        desc '내가 구독하는 토픽 unfollow'
        delete 'subscribed/:id' do
          topic = current_user.subscribed_topics.find_by(id: params[:id])
          error!({ message: 'Subscription not found' }, 404) if topic.nil?

          current_user.unfollow(topic)
          status 204
        end

        route_param :id do
          # GET /api/v1/my/topics/:id/follows
          desc '내 토픽 구독자 목록'
          get :follows do
            topic = find_my_topic!
            paginated_list(topic.topic_follows.includes(:user), Entities::TopicFollowEntity)
          end

          # POST /api/v1/my/topics/:id/invitations
          desc '내 토픽 구독자 초대'
          params do
            requires :people, type: Array do
              requires :email, type: String, regexp: /\S/
              optional :permissions, type: Array[String]
            end
          end
          post :invitations do
            topic = find_my_topic!

            people = params[:people] || []

            records = people.map do |follow_params|
              topic.invite(email: follow_params[:email].to_s.strip, permissions: follow_params[:permissions])
            end

            status 201
            {
              total: records.count,
              records: Entities::TopicFollowEntity.represent(records)
            }
          end

          # DELETE /api/v1/my/topics/:id/follow
          desc '내 토픽 구독자 해제'
          delete :follow do
            topic = find_my_topic!
            topic_follow = TopicFollow.find_by(topic: topic, user: current_user)
            error!({ message: 'Follow not found' }, 404) if topic_follow.nil?

            topic_follow.destroy!
            status 204
          end

          # PUT /api/v1/my/topics/:id/follows/:follow_id
          desc '내 토픽 구독자 권한 수정'
          params do
            requires :permissions, type: Array[String]
          end
          put 'follows/:follow_id' do
            topic = find_my_topic!

            topic_follow = topic.topic_follows.find_by(id: params[:follow_id])
            error!({ message: 'Follow not found' }, 404) if topic_follow.nil?

            topic_follow&.update!(permissions: params[:permissions])
            present topic_follow, with: Entities::TopicFollowEntity
          end

          # GET /api/v1/my/topics/:id
          desc '내 토픽 조회'
          get do
            topic = current_user.topics.find_by(id: params[:id])
            error!({ message: 'Topic not found' }, 404) if topic.nil?
            present topic, with: Entities::TopicEntity
          end

          # PATCH /api/v1/my/topics/:id
          desc '내 토픽 수정'
          params do
            optional :title, type: String, regexp: /\S/
            optional :is_default, type: Boolean
          end
          patch do
            topic = Topic.find_by(id: params[:id])
            error!({ message: 'Topic not found' }, 404) if topic.nil?
            error!({ message: 'Forbidden' }, 403) if topic.user_id != current_user.id

            updates = {}
            updates[:title] = params[:title].strip if params[:title].present?
            if params.key?(:is_default) && params[:is_default]
              current_user.topics.where(is_default: true).update_all(is_default: false)
              updates[:is_default] = true
            end

            topic.update!(updates)
            present topic, with: Entities::TopicEntity
          end

          # DELETE /api/v1/my/topics/:id
          desc '내 토픽 삭제'
          delete do
            topic = Topic.find_by(id: params[:id])
            error!({ message: 'Topic not found' }, 404) if topic.nil?
            error!({ message: 'Forbidden' }, 403) if topic.user_id != current_user.id

            topic.soft_delete!
            deleted_topic = Topic.unscoped.find(topic.id)
            status 200
            present deleted_topic, with: Entities::TopicEntity
          end
        end
      end
    end
  end
end
