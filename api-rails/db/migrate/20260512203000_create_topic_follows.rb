class CreateTopicFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :topic_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.datetime :followed_at
      t.datetime :invited_at
      t.jsonb :permissions, null: false, default: %w[create edit]

      t.timestamps
    end

    add_index :topic_follows, [:user_id, :topic_id], unique: true
  end
end
