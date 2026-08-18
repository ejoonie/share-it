module V1
  module My
    class EntriesAPI < Grape::API
      helpers ::Helpers::AuthenticationHelper

      helpers do
        def find_topic!
          topic = current_user.topics.find_by(id: params[:topic_id])
          error!({ message: 'Topic not found' }, 404) if topic.nil?
          topic
        end
      end

      # 생성/조회/수정/삭제는 V1::EntriesAPI(/api/v1/entries)가 담당한다 — 소유한
      # 토픽뿐 아니라 구독 중인 토픽까지 아우르고, follow 권한도 거기서 확인한다.
      # 여기 남은 목록 조회는 topic_id로 미리 좁혀서 조회하는 용도로 쇼핑리스트가 쓴다.
      resource :topics do
        route_param :topic_id do
          resource :entries do
            # GET /api/v1/my/topics/:topic_id/entries
            desc '엔트리 목록'
            params do
              optional :q, type: Hash, default: {} do
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
              topic = find_topic!

              paginated_list(topic.entries, Entities::EntryEntity)
            end
          end
        end
      end
    end
  end
end
