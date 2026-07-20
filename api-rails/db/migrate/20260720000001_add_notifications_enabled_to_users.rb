# frozen_string_literal: true

class AddNotificationsEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :notifications_enabled, :boolean, default: false, null: false
  end
end
