class User < ApplicationRecord
  has_secure_password validations: false

  before_validation :generate_token, on: :create

  validates :email, presence: true, uniqueness: true
  validates :nick_name, presence: true
  validates :token, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  LOGIN_CODE_TTL = 10.minutes

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

  # Generates a 6-digit numeric OTP, persists it, and returns the plain code.
  def generate_login_code!
    code = rand(100_000..999_999).to_s
    update!(login_code: code, login_code_expires_at: LOGIN_CODE_TTL.from_now)
    code
  end

  # Returns true when the supplied code matches and has not expired.
  def valid_login_code?(code)
    login_code.present? &&
      login_code_expires_at.present? &&
      login_code_expires_at > Time.current &&
      ActiveSupport::SecurityUtils.secure_compare(login_code.to_s, code.to_s)
  end

  # Clears the OTP after successful use.
  def consume_login_code!
    update_columns(login_code: nil, login_code_expires_at: nil)
  end

  def terms_accepted?
    terms_accepted_at.present?
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
