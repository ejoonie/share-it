class Topic < ApplicationRecord
  before_validation :generate_token, on: :create
  before_validation :set_default_permissions, on: :create

  default_scope { where(deleted_at: nil) }

  belongs_to :user
  has_many :topic_follows, dependent: :destroy
  has_many :followers, through: :topic_follows, source: :user

  validates :title, presence: true
  validates :token, presence: true, uniqueness: true
  validates :default_permissions, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.uuid
  end

  def set_default_permissions
    self.default_permissions ||= %w[create edit]
  end
end
