class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.string :owner_id, null: false
      t.string :title, null: false
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    add_index :topics, [:owner_id, :created_at]
  end
end
