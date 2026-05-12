class MigrateTopicsToUserId < ActiveRecord::Migration[7.2]
  def change
    add_reference :topics, :user, null: false, foreign_key: true
    remove_column :topics, :owner_id, :string
  end
end
