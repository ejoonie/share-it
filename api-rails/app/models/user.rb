class User < ApplicationRecord
  before_validation :generate_token, on: :create

  validates :email, presence: true, uniqueness: true
  validates :nick_name, presence: true
  validates :token, presence: true, uniqueness: true

  has_many :topics
  has_many :topic_follows, dependent: :destroy
  has_many :followed_topics, through: :topic_follows, source: :topic

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
