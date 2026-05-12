class User < ApplicationRecord
  before_validation :generate_token, on: :create

  validates :email, presence: true, uniqueness: true
  validates :nick_name, presence: true
  validates :token, presence: true, uniqueness: true

  has_many :topics

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
