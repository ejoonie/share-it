module V1
  class EntriesAPI < Grape::API
    helpers ::Helpers::AuthenticationHelper

    helpers do
      # 읽기는 구독 중이기만 하면 된다 (permission 명시 불필요).
      def find_followed_entry!(id)
        entry = Entry.where(topic_id: current_user.followed_topics.select(:id)).find_by(id: id)
        error!({ message: 'Entry not found' }, 404) if entry.nil?
        entry
      end

      def find_follow!(topic_id)
        follow = current_user.topic_follows.find_by(topic_id: topic_id)
        error!({ message: 'Topic not found' }, 404) if follow.nil?
        follow
      end

      # 쓰기(create/edit/delete)는 follow.permissions 에 해당 권한이 있어야 한다.
      def authorize!(follow, permission)
        error!({ message: 'Forbidden' }, 403) unless follow.permissions.to_a.include?(permission)
      end
    end

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

      # POST /api/v1/entries
      desc '구독 중인 토픽에 엔트리 생성 (follow permissions에 create 필요)'
      params do
        requires :topic_id, type: Integer
        optional :occurred_at, type: DateTime
        optional :kind, type: String
        optional :currency, type: String
        optional :amount, type: Integer
        optional :category, type: String
        optional :title, type: String
        optional :content, type: String
        optional :checked, type: Boolean
      end
      post do
        follow = find_follow!(params[:topic_id])
        authorize!(follow, 'create')

        entry = follow.topic.entries.create!(
          created_by: current_user,
          updated_by: current_user,
          occurred_at: params[:occurred_at],
          kind: params[:kind],
          currency: params[:currency] || 'usd',
          amount: params[:amount] || 0,
          category: params[:category],
          title: params[:title],
          content: params[:content],
          checked: params[:checked] || false
        )

        status 201
        present entry, with: Entities::EntryEntity
      end

      route_param :id do
        # GET /api/v1/entries/:id
        desc '엔트리 조회'
        get do
          entry = find_followed_entry!(params[:id])
          present entry, with: Entities::EntryEntity
        end

        # PATCH /api/v1/entries/:id
        desc '엔트리 수정 (follow permissions에 edit 필요)'
        params do
          optional :occurred_at, type: DateTime
          optional :kind, type: String
          optional :currency, type: String
          optional :amount, type: Integer
          optional :category, type: String
          optional :title, type: String
          optional :content, type: String
          optional :checked, type: Boolean
        end
        patch do
          entry = find_followed_entry!(params[:id])
          follow = find_follow!(entry.topic_id)
          authorize!(follow, 'edit')

          update_params = declared(params, include_missing: false).slice(
            :occurred_at, :kind, :currency, :amount, :category, :title, :content, :checked
          ).to_h
          update_params[:updated_by] = current_user

          entry.update!(update_params)
          present entry, with: Entities::EntryEntity
        end

        # DELETE /api/v1/entries/:id
        desc '엔트리 삭제 (follow permissions에 delete 필요)'
        delete do
          entry = find_followed_entry!(params[:id])
          follow = find_follow!(entry.topic_id)
          authorize!(follow, 'delete')

          entry.soft_delete!
          deleted_entry = Entry.unscoped.find(entry.id)
          status 200
          present deleted_entry, with: Entities::EntryEntity
        end
      end
    end
  end
end
