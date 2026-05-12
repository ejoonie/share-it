require "rails_helper"

RSpec.describe TopicFollow, type: :model do
  describe "validations" do
    it "is valid with default permissions" do
      topic_follow = TopicFollow.new(
        topic: topics(:one),
        user: users(:user_two),
        permissions: %w[create edit]
      )

      expect(topic_follow).to be_valid
    end

    it "is invalid with unsupported permissions" do
      topic_follow = TopicFollow.new(
        topic: topics(:one),
        user: users(:user_two),
        permissions: %w[owner]
      )

      expect(topic_follow).not_to be_valid
      expect(topic_follow.errors[:permissions]).to include("contains invalid values")
    end

    it "is invalid for duplicated user/topic pair" do
      topic_follow = TopicFollow.new(
        topic: topics(:one),
        user: users(:user_one),
        permissions: %w[create]
      )

      expect(topic_follow).not_to be_valid
      expect(topic_follow.errors[:user_id]).to include("has already been taken")
    end
  end
end
