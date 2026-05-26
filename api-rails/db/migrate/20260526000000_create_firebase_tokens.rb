class CreateFirebaseTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :firebase_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :last_failed_at

      t.timestamps
    end

    add_index :firebase_tokens, :token, unique: true
  end
end
