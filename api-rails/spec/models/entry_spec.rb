require "rails_helper"

RSpec.describe Entry, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      entry = Entry.new(
        topic: topics(:one),
        created_by: users(:user_one),
        updated_by: users(:user_one),
        currency: 'usd',
        amount: 100
      )
      expect(entry).to be_valid
    end

    it "is invalid without a topic" do
      entry = Entry.new(
        topic: nil,
        created_by: users(:user_one),
        currency: 'usd',
        amount: 0
      )
      expect(entry).not_to be_valid
      expect(entry.errors[:topic]).to include("must exist")
    end

    it "is invalid without a created_by" do
      entry = Entry.new(
        topic: topics(:one),
        created_by: nil,
        currency: 'usd',
        amount: 0
      )
      expect(entry).not_to be_valid
      expect(entry.errors[:created_by]).to include("must exist")
    end

    it "is valid without an updated_by" do
      entry = Entry.new(
        topic: topics(:one),
        created_by: users(:user_one),
        updated_by: nil,
        currency: 'usd',
        amount: 0
      )
      expect(entry).to be_valid
    end

    it "defaults currency to usd" do
      entry = Entry.create!(
        topic: topics(:one),
        created_by: users(:user_one),
        amount: 0
      )
      expect(entry.currency).to eq('usd')
    end

    it "defaults amount to 0" do
      entry = Entry.create!(
        topic: topics(:one),
        created_by: users(:user_one)
      )
      expect(entry.amount).to eq(0)
    end

    it "defaults checked to false" do
      entry = Entry.create!(
        topic: topics(:one),
        created_by: users(:user_one)
      )
      expect(entry.checked).to eq(false)
    end
  end

  describe "scopes and soft delete" do
    it "default scope excludes soft deleted records" do
      expect(Entry.all).not_to include(entries(:entry_deleted))
      expect(Entry.all).to include(entries(:entry_one))
    end

    it "soft_delete! sets deleted_at" do
      entry = entries(:entry_one)
      expect(entry.deleted_at).to be_nil
      entry.soft_delete!
      deleted = Entry.unscoped.find(entry.id)
      expect(deleted.deleted_at).not_to be_nil
    end

    it "soft deleted entries are excluded from default scope" do
      entry = entries(:entry_one)
      entry.soft_delete!
      expect(Entry.find_by(id: entry.id)).to be_nil
    end
  end

  describe "associations" do
    it "belongs to topic" do
      entry = entries(:entry_one)
      expect(entry.topic).to eq(topics(:one))
    end

    it "belongs to created_by user" do
      entry = entries(:entry_one)
      expect(entry.created_by).to eq(users(:user_one))
    end

    it "belongs to updated_by user" do
      entry = entries(:entry_one)
      expect(entry.updated_by).to eq(users(:user_one))
    end
  end
end
