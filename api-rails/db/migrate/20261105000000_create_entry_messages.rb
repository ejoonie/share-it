class CreateEntryMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_messages do |t|
      t.references :entry, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :body, null: false
      t.timestamps
    end
    add_index :entry_messages, [:entry_id, :id]
    add_check_constraint :entry_messages, "char_length(body) BETWEEN 1 AND 2000", name: "entry_messages_body_length"
  end
end
