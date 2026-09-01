# frozen_string_literal: true

class AddLastSeenAtToDeviceTokens < ActiveRecord::Migration[7.2]
  def change
    add_column :device_tokens, :last_seen_at, :datetime
  end
end
