class Topic < ApplicationRecord
  before_validation :generate_token, on: :create
  before_validation :set_default_permissions, on: :create

  default_scope { where(deleted_at: nil) }

  belongs_to :user
  has_many :topic_follows, dependent: :destroy
  has_many :followers, through: :topic_follows, source: :user
  has_many :entries, dependent: :destroy

  validates :title, presence: true
  validates :token, presence: true, uniqueness: true
  validates :default_permissions, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def invite(email:, permissions:)
    user = User.find_or_initialize_by(email: email)
    user.nick_name ||= email.split('@').first
    user.save! if user.new_record?

    topic_follow = TopicFollow.find_or_initialize_by(topic: self, user: user)
    topic_follow.permissions = permissions.present? ? permissions : default_permissions
    topic_follow.invited_at ||= Time.current
    topic_follow.save!
    topic_follow
  end

  private

  def generate_token
    self.token ||= SecureRandom.uuid
  end

  def set_default_permissions
    self.default_permissions ||= %w[create edit]
  end
end
