require "rails_helper"

RSpec.describe Topic, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      topic = Topic.new(user: users(:user_one), title: "My Topic", is_default: false)
      expect(topic).to be_valid
    end

    it "is invalid without a title" do
      topic = Topic.new(user: users(:user_one), title: nil, is_default: false)
      expect(topic).not_to be_valid
      expect(topic.errors[:title]).to include("can't be blank")
    end

    it "is invalid with an empty title" do
      topic = Topic.new(user: users(:user_one), title: "", is_default: false)
      expect(topic).not_to be_valid
      expect(topic.errors[:title]).to include("can't be blank")
    end

    it "is valid with spaces in title" do
      topic = Topic.new(user: users(:user_one), title: "My Topic With Spaces", is_default: false)
      expect(topic).to be_valid
    end

    it "is invalid without a user" do
      topic = Topic.new(user: nil, title: "My Topic", is_default: false)
      expect(topic).not_to be_valid
      expect(topic.errors[:user]).to include("must exist")
    end
  end

  describe "scopes and soft delete" do
    it "default scope excludes soft deleted records" do
      expect(Topic.all).not_to include(topics(:deleted))
      expect(Topic.all).to include(topics(:one))
    end

    it "soft_delete! sets deleted_at" do
      topic = topics(:one)
      expect(topic.deleted_at).to be_nil
      topic.soft_delete!
      deleted = Topic.unscoped.find(topic.id)
      expect(deleted.deleted_at).not_to be_nil
    end

    it "soft deleted topics are excluded from default scope" do
      topic = topics(:one)
      topic.soft_delete!
      expect(Topic.find_by(id: topic.id)).to be_nil
    end
  end
end

