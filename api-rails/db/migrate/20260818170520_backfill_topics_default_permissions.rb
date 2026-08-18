class BackfillTopicsDefaultPermissions < ActiveRecord::Migration[7.2]
  def up
    topic_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'topics'
    end

    topic_model.where(deleted_at: nil).find_each do |topic|
      next if topic.default_permissions.include?('delete')

      topic.update_columns(default_permissions: topic.default_permissions + ['delete'])
    end
  end

  def down
    # 되돌릴 필요 없음: 기본 권한에는 항상 delete가 포함되어야 한다.
  end
end
