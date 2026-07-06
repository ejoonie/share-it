class AddAuthFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :login_code, :string
    add_column :users, :login_code_expires_at, :datetime
    add_column :users, :terms_accepted_at, :datetime
  end
end
