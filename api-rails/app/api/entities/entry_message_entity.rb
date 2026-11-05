module Entities
  class EntryMessageEntity < Grape::Entity
    expose :id, :entry_id, :body, :created_at, :updated_at
    expose :author do |message|
      { id: message.user_id, nick_name: message.user.nick_name }
    end
  end
end
