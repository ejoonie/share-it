module Entities
  class EntryEntity < Grape::Entity
    expose :id
    expose :topic_id
    expose :created_by_id
    expose :updated_by_id
    expose :occurred_at
    expose :kind
    expose :currency
    expose :amount
    expose :category
    expose :title
    expose :content
    expose :checked
    expose :deleted_at
    expose :created_at
    expose :updated_at
    # options[:read_entry_ids]가 주어진 요청(예: GET /api/v1/entries)에서만 실제 값을 노출하고,
    # 그렇지 않은 요청(예: 토픽 단위 CRUD)에서는 false를 내려준다.
    expose :read do |entry, options|
      ids = options[:read_entry_ids]
      ids ? ids.include?(entry.id) : false
    end
  end
end
