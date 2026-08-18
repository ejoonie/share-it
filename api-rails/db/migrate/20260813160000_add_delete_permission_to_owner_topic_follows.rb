class AddDeletePermissionToOwnerTopicFollows < ActiveRecord::Migration[7.2]
  def up
    topic_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'topics'
    end
    topic_follow_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'topic_follows'
    end

    topic_model.where(deleted_at: nil).find_each do |topic|
      follow = topic_follow_model.find_by(user_id: topic.user_id, topic_id: topic.id)
      next if follow.nil? || follow.permissions.include?('delete')

      follow.update!(permissions: follow.permissions + ['delete'])
    end
  end

  def down
    # 되돌릴 필요 없음: 토픽 소유자는 항상 자신의 토픽에 대한 delete 권한을 가져야 한다.
  end
end
