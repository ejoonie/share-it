require 'securerandom'

class AddTokenAndDefaultPermissionsToTopics < ActiveRecord::Migration[7.2]
  def change
    add_column :topics, :token, :string
    add_column :topics, :default_permissions, :jsonb, null: false, default: %w[create edit]

    reversible do |dir|
      dir.up do
        topic_model = Class.new(ActiveRecord::Base) do
          self.table_name = 'topics'
        end

        topic_model.where(token: nil).find_each do |topic|
          topic.update_columns(token: SecureRandom.uuid)
        end
      end
    end

    change_column_null :topics, :token, false
    add_index :topics, :token, unique: true
  end
end
