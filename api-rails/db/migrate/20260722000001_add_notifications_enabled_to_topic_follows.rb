class AddNotificationsEnabledToTopicFollows < ActiveRecord::Migration[7.1]
  def change
    add_column :topic_follows, :notifications_enabled, :boolean, default: true, null: false
  end
end
