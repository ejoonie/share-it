module V1
  class TopicsAPI < Grape::API
    helpers do
      def current_user
        token = headers['x-token'] || headers['X-Token']
        error!({ message: 'x-token header is required' }, 401) unless token
        @current_user ||= User.find_by(token: token)
        error!({ message: 'Unauthorized' }, 401) unless @current_user
        @current_user
      end

      def find_topic!
        topic = Topic.find_by(id: params[:id])
        error!({ message: 'Topic not found' }, 404) if topic.nil?
        topic
      end

      def authorize_topic_owner!(topic)
        error!({ message: 'Forbidden' }, 403) if topic.user_id != current_user.id
      end
    end

    resource :topics do
      # POST /api/v1/topics
      desc '토픽 생성'
      params do
        requires :title, type: String, regexp: /\S/
      end
      post do
        title = params[:title].strip

        topic = Topic.create!(
          user: current_user,
          title: title,
          is_default: false
        )

        status 201
        present topic, with: Entities::TopicEntity
      end

      # GET /api/v1/topics/owned
      desc '내 토픽 목록'
      get :owned do
        topics = current_user.topics.order(created_at: :desc)
        { total: topics.count, records: Entities::TopicEntity.represent(topics) }
      end

      route_param :id do
        # POST /api/v1/topics/:id/follow
        desc '토픽 구독'
        post :follow do
          topic = find_topic!

          topic_follow = TopicFollow.find_or_initialize_by(topic: topic, user: current_user)
          if topic_follow.new_record?
            topic_follow.followed_at = Time.current
            topic_follow.permissions = topic.default_permissions
            topic_follow.save!
            status 201
          else
            status 200
          end
          present topic_follow, with: Entities::TopicFollowEntity
        end

        # DELETE /api/v1/topics/:id/follow
        desc '토픽 구독 해제'
        delete :follow do
          topic = find_topic!
          topic_follow = TopicFollow.find_by(topic: topic, user: current_user)
          error!({ message: 'Follow not found' }, 404) if topic_follow.nil?

          topic_follow.destroy!
          status 204
        end

        # GET /api/v1/topics/:id/follows
        desc '토픽 구독자 목록'
        get :follows do
          topic = find_topic!
          authorize_topic_owner!(topic)

          topic_follows = topic.topic_follows.includes(:user).order(created_at: :desc)
          {
            total: topic_follows.count,
            records: Entities::TopicFollowEntity.represent(topic_follows)
          }
        end

        # POST /api/v1/topics/:id/follows
        desc '토픽 구독자 초대'
        params do
          optional :follows, type: Array do
            requires :email, type: String, regexp: /\S/
            optional :permissions, type: Array[String]
          end
          optional :email, type: String, regexp: /\S/
          optional :permissions, type: Array[String]
        end
        post :follows do
          topic = find_topic!
          authorize_topic_owner!(topic)

          follows_params = params[:follows] || []
          follows_params = [{ email: params[:email], permissions: params[:permissions] }] if follows_params.empty? && params[:email].present?
          error!({ message: 'follows or email is required' }, 400) if follows_params.empty?

          records = follows_params.map do |follow_params|
            user = User.find_by(email: follow_params[:email].to_s.strip)
            error!({ message: "User not found: #{follow_params[:email]}" }, 404) if user.nil?

            topic_follow = TopicFollow.find_or_initialize_by(topic: topic, user: user)
            topic_follow.permissions = follow_params[:permissions] if follow_params[:permissions].present?
            topic_follow.permissions = topic.default_permissions if topic_follow.permissions.blank?
            topic_follow.invited_at ||= Time.current
            topic_follow.save!
            topic_follow
          end

          status 201
          {
            total: records.count,
            records: Entities::TopicFollowEntity.represent(records)
          }
        end

        # PUT /api/v1/topics/:id/follows/:follow_id
        desc '토픽 구독자 권한 수정'
        params do
          requires :permissions, type: Array[String]
        end
        put 'follows/:follow_id' do
          topic = find_topic!
          authorize_topic_owner!(topic)

          topic_follow = topic.topic_follows.find_by(id: params[:follow_id])
          error!({ message: 'Follow not found' }, 404) if topic_follow.nil?

          topic_follow.update!(permissions: params[:permissions])
          present topic_follow, with: Entities::TopicFollowEntity
        end

        # GET /api/v1/topics/:id
        desc '토픽 조회'
        get do
          topic = current_user.topics.find_by(id: params[:id])
          error!({ message: 'Topic not found' }, 404) if topic.nil?
          present topic, with: Entities::TopicEntity
        end

        # PATCH /api/v1/topics/:id
        desc '토픽 수정'
        params do
          requires :title, type: String, regexp: /\S/
        end
        patch do
          topic = Topic.find_by(id: params[:id])
          error!({ message: 'Topic not found' }, 404) if topic.nil?
          error!({ message: 'Forbidden' }, 403) if topic.user_id != current_user.id

          topic.update!(title: params[:title].strip)
          present topic, with: Entities::TopicEntity
        end

        # DELETE /api/v1/topics/:id
        desc '토픽 삭제'
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
