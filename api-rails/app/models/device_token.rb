class DeviceToken < ApplicationRecord
  PLATFORMS = %w[ios android].freeze

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, inclusion: { in: PLATFORMS }
end
