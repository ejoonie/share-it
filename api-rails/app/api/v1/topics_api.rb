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

      def find_topic_by_token!
        topic = Topic.find_by(token: params[:token])
        error!({ message: 'Topic not found' }, 404) if topic.nil?
        topic
      end
    end

    resource :topics do
      route_param :token do
        # GET /api/v1/topics/:token
        desc '토픽 조회 (공개 토픽)'
        get do
          topic = find_topic_by_token!
          present topic, with: Entities::TopicEntity
        end

        # POST /api/v1/topics/:token/follow
        desc '토픽 구독 (공개 토픽)'
        post :follow do
          topic = find_topic_by_token!
          topic_follow = current_user.follow(topic) # 이미 팔로우한 경우에도 아무런 변화 없이 성공 처리
          status 201
          present topic_follow, with: Entities::TopicFollowEntity
        end
      end
    end
  end
end
