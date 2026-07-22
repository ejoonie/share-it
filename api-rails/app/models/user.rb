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

  def accept_terms!
    update!(terms_accepted_at: Time.current)
  end

  # 계정과 연관 데이터를 모두 삭제한다 (회원탈퇴).
  def delete_with_data!
    ActiveRecord::Base.transaction do
      topic_ids = Topic.where(user_id: id).pluck(:id)
      Entry.where(topic_id: topic_ids).delete_all if topic_ids.any?
      Topic.where(user_id: id).delete_all
      TopicFollow.where(user_id: id).delete_all
      destroy!
    end
  end

  # 게스트 계정의 데이터를 target_user로 이전하고 자신을 삭제한다.
  # - 내 topic(피기): target_user로 소유권 이전
  #   - target_user에 이미 default topic이 있으면, 게스트 topic의 entry를 그쪽으로 옮기고 게스트 topic 삭제
  #   - target_user에 topic이 없으면 게스트 topic을 그대로 이전
  # - 내가 팔로우하던 topic: target_user로 이전 (충돌 시 target_user 것 유지)
  # - 나를 팔로우하던 구독: 모두 삭제
  # - entry (created_by / updated_by): target_user로 이전
  # 반드시 is_guest? == true 인 유저에서 호출해야 한다.
  def merge_into!(target_user)
    raise ArgumentError, 'Only guest accounts can be merged' unless is_guest?

    ActiveRecord::Base.transaction do
      my_topic_ids = topics.pluck(:id)

      # 샘플 entry 삭제 (이전 전에 제거)
      Entry.where(topic_id: my_topic_ids, is_sample: true).delete_all if my_topic_ids.any?

      # target_user의 기존 default topic 확인
      target_default_topic = target_user.topics.find_by(is_default: true) ||
                             target_user.topics.order(created_at: :asc).first

      if target_default_topic && my_topic_ids.any?
        # target_user에 이미 topic이 있으면: 게스트 entry를 target의 default topic으로 이동
        # unscoped: soft-deleted entry도 이동해야 FK 위반 없이 guest topic을 삭제할 수 있다
        Entry.unscoped.where(topic_id: my_topic_ids, is_sample: false)
             .update_all(topic_id: target_default_topic.id)
        # 남은 sample entry(soft-delete 포함)는 하드 삭제
        Entry.unscoped.where(topic_id: my_topic_ids).delete_all
        # 게스트 topic 삭제 (entry가 이미 이전/삭제되었으므로 빈 상태) — 나를 팔로우하던 구독도 함께 삭제
        TopicFollow.where(topic_id: my_topic_ids).delete_all
        Topic.where(id: my_topic_ids).delete_all
      else
        # target_user에 topic이 없으면: 게스트 topic 소유권 이전
        topics.update_all(user_id: target_user.id)

        # 내가 내 topic을 팔로우하던 구독 → target_user로 이전 (이미 팔로우 중이면 스킵)
        topic_follows.where(topic_id: my_topic_ids).each do |tf|
          unless TopicFollow.exists?(user_id: target_user.id, topic_id: tf.topic_id)
            tf.update_columns(user_id: target_user.id)
          end
        end

        # 나를 팔로우하던 구독(다른 유저가 게스트 topic을 팔로우)은 삭제
        TopicFollow.where(topic_id: my_topic_ids).where.not(user_id: id).delete_all
      end

      # 내가 팔로우하던 남의 topic → target_user로 이전 (이미 팔로우 중이면 스킵)
      topic_follows.reload.each do |tf|
        unless TopicFollow.exists?(user_id: target_user.id, topic_id: tf.topic_id)
          tf.update_columns(user_id: target_user.id)
        end
      end
      topic_follows.reload.delete_all

      # entry 이전 (샘플 데이터 제외)
      Entry.where(created_by_id: id, is_sample: false).update_all(created_by_id: target_user.id)
      Entry.where(updated_by_id: id, is_sample: false).update_all(updated_by_id: target_user.id)

      destroy!
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
