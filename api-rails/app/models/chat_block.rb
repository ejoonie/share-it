class ChatBlock < ApplicationRecord
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'
  after_commit :refresh_conversations, on: [:create, :destroy]

  validates :blocked_id, uniqueness: { scope: :blocker_id }
  validate :different_users

  def self.between?(first_user_id, second_user_id)
    where(blocker_id: first_user_id, blocked_id: second_user_id)
      .or(where(blocker_id: second_user_id, blocked_id: first_user_id))
      .exists?
  end

  def self.counterpart_ids(user_id)
    where('blocker_id = :id OR blocked_id = :id', id: user_id).pluck(:blocker_id, :blocked_id)
      .map { |blocker_id, blocked_id| blocker_id == user_id ? blocked_id : blocker_id }
      .uniq
  end

  private

  def refresh_conversations
    # Refresh already-loaded history in every shared conversation, on both devices.
    topic_ids = TopicFollow.where(user_id: blocker_id).select(:topic_id)
    shared_ids = TopicFollow.where(user_id: blocked_id, topic_id: topic_ids).select(:topic_id)
    Entry.where(topic_id: shared_ids).find_each do |entry|
      ActionCable.server.broadcast("entry_chat_#{entry.id}", { type: 'changed' })
    end
  rescue StandardError => error
    Rails.logger.error("Chat block refresh failed: #{error.class}")
  end

  def different_users
    errors.add(:blocked, 'cannot be yourself') if blocker_id.present? && blocker_id == blocked_id
  end
end
