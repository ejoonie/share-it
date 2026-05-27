class AddIsGuestToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_guest, :boolean, null: false, default: false
  end
end
