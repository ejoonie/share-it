module V1
  class TopicsAPI < Grape::API
    helpers do
      def x_user_id
        headers['x-user-id'] || headers['X-User-Id'] || error!({ message: 'x-user-id header is required' }, 401)
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
          owner_id: x_user_id,
          title: title,
          is_default: false
        )

        status 201
        present topic, with: Entities::TopicEntity
      end

      # GET /api/v1/topics/owned
      desc '내 토픽 목록'
      get :owned do
        topics = Topic.where(owner_id: x_user_id).order(created_at: :desc)
        { topics: Entities::TopicEntity.represent(topics) }
      end

      route_param :id do
        # GET /api/v1/topics/:id
        desc '토픽 조회'
        get do
          topic = Topic.find_by(id: params[:id])
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
          error!({ message: 'Forbidden' }, 403) if topic.owner_id != x_user_id

          topic.update!(title: params[:title].strip)
          present topic, with: Entities::TopicEntity
        end

        # DELETE /api/v1/topics/:id
        desc '토픽 삭제'
        delete do
          topic = Topic.find_by(id: params[:id])
          error!({ message: 'Topic not found' }, 404) if topic.nil?
          error!({ message: 'Forbidden' }, 403) if topic.owner_id != x_user_id

          topic.soft_delete!
          deleted_topic = Topic.unscoped.find(topic.id)
          status 200
          present deleted_topic, with: Entities::TopicEntity
        end
      end
    end
  end
end
