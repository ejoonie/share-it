class CreateChatSafety < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :blocked, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps
    end
    add_index :chat_blocks, [:blocker_id, :blocked_id], unique: true
    add_check_constraint :chat_blocks, 'blocker_id <> blocked_id', name: 'chat_blocks_different_users'

    create_table :message_reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :reported_user, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :entry, null: true, foreign_key: { on_delete: :nullify }
      t.references :entry_message, null: true, foreign_key: { on_delete: :nullify }
      t.string :reason, null: false
      t.string :status, null: false, default: 'pending'
      t.text :body_snapshot, null: false
      t.timestamps
    end
    add_index :message_reports, [:reporter_id, :entry_message_id],
      unique: true, where: 'entry_message_id IS NOT NULL', name: 'index_unique_message_reports'
    add_check_constraint :message_reports,
      "reason IN ('harassment', 'sexual_content', 'violence', 'spam', 'other')",
      name: 'message_reports_reason'
    add_check_constraint :message_reports,
      "status IN ('pending', 'reviewed', 'actioned', 'dismissed')",
      name: 'message_reports_status'
  end
end
