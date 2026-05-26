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

        def find_entry!(topic)
          entry = topic.entries.find_by(id: params[:id])
          error!({ message: 'Entry not found' }, 404) if entry.nil?
          entry
        end
      end

      resource :topics do
        route_param :topic_id do
          resource :entries do
            # POST /api/v1/my/topics/:topic_id/entries
            desc '엔트리 생성'
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
            post do
              topic = find_topic!

              entry = topic.entries.create!(
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

            # GET /api/v1/my/topics/:topic_id/entries
            desc '엔트리 목록'
            get do
              topic = find_topic!

              entries = topic.entries.order(created_at: :desc)
              { total: entries.count, records: Entities::EntryEntity.represent(entries) }
            end

            route_param :id do
              # GET /api/v1/my/topics/:topic_id/entries/:id
              desc '엔트리 조회'
              get do
                topic = find_topic!
                entry = find_entry!(topic)
                present entry, with: Entities::EntryEntity
              end

              # PATCH /api/v1/my/topics/:topic_id/entries/:id
              desc '엔트리 수정'
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
                topic = find_topic!
                entry = find_entry!(topic)

                update_params = declared(params, include_missing: false).slice(
                  :occurred_at, :kind, :currency, :amount, :category, :title, :content, :checked
                ).to_h
                update_params[:updated_by] = current_user

                entry.update!(update_params)
                present entry, with: Entities::EntryEntity
              end

              # DELETE /api/v1/my/topics/:topic_id/entries/:id
              desc '엔트리 삭제'
              delete do
                topic = find_topic!
                entry = find_entry!(topic)

                entry.soft_delete!
                deleted_entry = Entry.unscoped.find(entry.id)
                status 200
                present deleted_entry, with: Entities::EntryEntity
              end
            end
          end
        end
      end
    end
  end
end
