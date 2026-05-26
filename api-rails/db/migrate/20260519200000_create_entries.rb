class CreateEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :entries do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: true, foreign_key: { to_table: :users }

      t.datetime :occurred_at
      t.string :kind
      t.string :currency, null: false, default: 'usd'
      t.integer :amount, null: false, default: 0
      t.string :category
      t.string :title
      t.string :content
      t.boolean :checked, null: false, default: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :entries, :deleted_at
  end
end
