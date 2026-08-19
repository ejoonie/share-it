class CreateEntryReads < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :entry_reads, [:user_id, :entry_id], unique: true
  end
end
