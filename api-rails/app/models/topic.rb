class Topic < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :user
  validates :title, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
