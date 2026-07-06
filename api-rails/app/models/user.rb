class User < ApplicationRecord
  has_secure_password validations: false

  before_validation :generate_token, on: :create

  validates :email, presence: true, uniqueness: true
  validates :nick_name, presence: true
  validates :token, presence: true, uniqueness: true

  has_many :topics
  has_many :topic_follows, dependent: :destroy
  has_many :followed_topics, through: :topic_follows, source: :topic
  has_many :owned_entries, through: :topics, source: :entries
  has_many :created_entries, class_name: 'Entry', foreign_key: 'created_by_id'
  has_many :updated_entries, class_name: 'Entry', foreign_key: 'updated_by_id'

  def follow(topic)
    topic_follow = TopicFollow.find_or_initialize_by(topic: topic, user: self)
    if topic_follow.new_record?
      topic_follow.followed_at = Time.current
      topic_follow.permissions = topic.default_permissions
      topic_follow.save!
    end
    topic_follow
  end

  def unfollow(topic)
    topic_follow = TopicFollow.find_by(topic: topic, user: self)
    topic_follow&.destroy!
  end

  def subscribed_topics
    Topic.where(id: topic_follows.select(:topic_id))
  end

  def generate_otp!
    self.otp_code = SecureRandom.random_number(100_000..999_999).to_s
    self.otp_expires_at = 10.minutes.from_now
    save!
    otp_code
  end

  def verify_otp!(code)
    return false if otp_code.nil? || otp_expires_at.nil?
    return false if Time.current > otp_expires_at
    return false if otp_code != code.to_s.strip

    update!(otp_code: nil, otp_expires_at: nil)
    true
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
