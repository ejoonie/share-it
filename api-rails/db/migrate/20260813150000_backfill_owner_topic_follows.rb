class BackfillOwnerTopicFollows < ActiveRecord::Migration[7.2]
  def up
    topic_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'topics'
    end
    topic_follow_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'topic_follows'
    end

    topic_model.where(deleted_at: nil).find_each do |topic|
      next if topic_follow_model.exists?(user_id: topic.user_id, topic_id: topic.id)

      topic_follow_model.create!(
        user_id: topic.user_id,
        topic_id: topic.id,
        followed_at: topic.created_at,
        permissions: topic.default_permissions
      )
    end
  end

  def down
    # 되돌릴 필요 없음: 토픽 소유자는 항상 자신의 토픽을 구독한 상태여야 한다.
  end
end
