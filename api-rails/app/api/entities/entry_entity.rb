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
  end
end
