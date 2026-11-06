class MessageReport < ApplicationRecord
  REASONS = %w[harassment sexual_content violence spam other].freeze
  STATUSES = %w[pending reviewed actioned dismissed].freeze

  belongs_to :reporter, class_name: 'User'
  belongs_to :reported_user, class_name: 'User', optional: true
  belongs_to :entry, optional: true
  belongs_to :entry_message, optional: true

  validates :reason, inclusion: { in: REASONS }
  validates :status, inclusion: { in: STATUSES }
  validates :body_snapshot, presence: true
end
