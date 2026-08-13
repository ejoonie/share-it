module V1
  class EntriesAPI < Grape::API
    helpers ::Helpers::AuthenticationHelper

    resource :entries do
      # GET /api/v1/entries
      desc '내가 구독하는 모든 토픽의 엔트리 목록 (q[topic_id_in][]으로 특정 토픽만 필터링 가능, 기본은 전체)'
      params do
        optional :q, type: Hash, default: {} do
          optional :topic_id_in, type: Array[Integer]
          optional :kind_eq, type: String
          optional :currency_eq, type: String
          optional :amount_eq, type: Integer
          optional :amount_gteq, type: Integer
          optional :amount_lteq, type: Integer
          optional :category_eq, type: String
          optional :title_cont, type: String
          optional :content_cont, type: String
          optional :checked_eq, type: Boolean
          optional :occurred_at_gteq, type: DateTime
          optional :occurred_at_lteq, type: DateTime
          optional :created_at_gteq, type: DateTime
          optional :created_at_lteq, type: DateTime
          optional :s, type: String
        end
      end
      get do
        scope = Entry.where(topic_id: current_user.followed_topics.select(:id))
        paginated_list(scope, Entities::EntryEntity)
      end
    end
  end
end
