class Entry < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :topic
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by_id', optional: true

  validates :currency, presence: true
  validates :amount, presence: true, numericality: { only_integer: true }
  validates :checked, inclusion: { in: [true, false] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[kind currency amount category title content checked occurred_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
