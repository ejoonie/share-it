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
  has_many :device_tokens, dependent: :destroy
  has_many :entry_reads, dependent: :destroy

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

  # 내가 소유하거나 구독하는 모든 토픽 (달력 등에서 "전체 보기"의 기본 범위)
  def accessible_topics
    Topic.where(id: topics.select(:id)).or(Topic.where(id: followed_topics.select(:id)))
  end

  # entry를 (이미 읽었으면 조용히 무시하고) 읽음 처리한다.
  def mark_entry_read!(entry)
    EntryRead.find_or_create_by!(user: self, entry: entry) { |r| r.read_at = Time.current }
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

  def accept_terms!
    update!(terms_accepted_at: Time.current)
  end

  # 계정과 연관 데이터를 모두 삭제한다 (회원탈퇴).
  def delete_with_data!
    ActiveRecord::Base.transaction do
      # unscoped: 내가 소유했던 soft-deleted topic도 포함해야 FK 위반 없이 정리할 수 있다
      topic_ids = Topic.unscoped.where(user_id: id).pluck(:id)
      if topic_ids.any?
        entry_ids = Entry.unscoped.where(topic_id: topic_ids).pluck(:id)
        # entry_reads가 entry를 FK로 참조하므로 entry보다 먼저 지운다 (다른 구독자의 읽음 기록 포함)
        EntryRead.where(entry_id: entry_ids).delete_all if entry_ids.any?
        Entry.unscoped.where(topic_id: topic_ids).delete_all
        # 나를 팔로우하던 구독도 삭제
        TopicFollow.where(topic_id: topic_ids).delete_all
        Topic.unscoped.where(id: topic_ids).delete_all
      end
      TopicFollow.where(user_id: id).delete_all
      destroy!
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
