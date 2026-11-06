class EntryMessage < ApplicationRecord
  after_commit :broadcast_change, on: [:create, :update, :destroy]

  belongs_to :entry
  belongs_to :user

  before_validation { self.body = body.strip if body.is_a?(String) }
  validates :body, presence: true, length: { maximum: 2000 }
  validate :body_is_safe
  private

  def body_is_safe
    errors.add(:body, 'contains prohibited content') if body.present? && ChatContentFilter.blocked?(body)
  end

  def broadcast_change
    # Invalidation only: clients fetch content through the authorized REST API.
    ActionCable.server.broadcast(
      "entry_chat_#{entry_id}",
      { type: 'changed', message_id: id, author_id: user_id }
    )
  rescue StandardError => error
    # A transport outage must not turn a committed write into a failed POST.
    Rails.logger.error("Chat broadcast failed: #{error.class}")
  end
end
