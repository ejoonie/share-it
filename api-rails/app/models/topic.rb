class Topic < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  validates :owner_id, presence: true
  validates :title, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
