require "rails_helper"

RSpec.describe EntryRead, type: :model do
  it "is valid with a user, entry and read_at" do
    er = EntryRead.new(user: users(:user_two), entry: entries(:entry_one), read_at: Time.current)

    expect(er).to be_valid
  end

  it "does not allow the same user to read the same entry twice" do
    EntryRead.create!(user: users(:user_two), entry: entries(:entry_one), read_at: Time.current)
    dup = EntryRead.new(user: users(:user_two), entry: entries(:entry_one), read_at: Time.current)

    expect(dup).not_to be_valid
  end

  it "allows different users to read the same entry" do
    EntryRead.create!(user: users(:user_two), entry: entries(:entry_one), read_at: Time.current)
    other = EntryRead.new(user: users(:guest_user), entry: entries(:entry_one), read_at: Time.current)

    expect(other).to be_valid
  end
end
