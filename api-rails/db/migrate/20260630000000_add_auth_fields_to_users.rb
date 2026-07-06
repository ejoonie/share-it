class AddAuthFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :otp_code, :string
    add_column :users, :otp_expires_at, :datetime
  end
end
