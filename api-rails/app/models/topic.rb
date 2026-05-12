class Topic < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :user
  has_many :topic_follows, dependent: :destroy
  has_many :followers, through: :topic_follows, source: :user
  validates :title, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
