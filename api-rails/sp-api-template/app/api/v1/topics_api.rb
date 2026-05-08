module V1
  class TopicsAPI < Grape::API
    format :json

    helpers do
      def user_id
        headers['x-user-id'] || headers['X-User-Id'] || error!({ message: 'x-user-id header is required' }, 401)
      end
    end

    resource :topics do
      desc '토픽 생성'
      params do
        requires :title, type: String
      end
      post do
        title = params[:title].to_s.strip
        error!({ message: 'title is required' }, 400) if title.empty?

        topic = Topic.create!(
          owner_id: user_id,
          title: title,
          is_default: false
        )

        status 201
        present topic, with: Entities::TopicEntity
      end

      desc '내 토픽 목록'
      get :owned do
        topics = Topic.where(owner_id: user_id).order(created_at: :desc)
        { topics: Entities::TopicEntity.represent(topics) }
      end
    end
  end
end
