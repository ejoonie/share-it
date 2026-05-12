class TopicFollow < ApplicationRecord
  ALLOWED_PERMISSIONS = %w[create edit delete admin banned].freeze

  belongs_to :user
  belongs_to :topic

  validates :permissions, presence: true
  validates :user_id, uniqueness: { scope: :topic_id }
  validate :validate_permissions

  private

  def validate_permissions
    return if permissions.blank?
    return if permissions.is_a?(Array) && (permissions - ALLOWED_PERMISSIONS).empty?

    errors.add(:permissions, "contains invalid values")
  end
end
