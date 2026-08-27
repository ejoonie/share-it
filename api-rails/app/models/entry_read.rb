class EntryRead < ApplicationRecord
  belongs_to :user
  belongs_to :entry

  validates :user_id, uniqueness: { scope: :entry_id }
end
