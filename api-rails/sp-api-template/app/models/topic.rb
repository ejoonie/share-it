class Topic < ApplicationRecord
  validates :owner_id, presence: true
  validates :title, presence: true
end
