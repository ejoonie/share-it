require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(email: "test@example.com", nick_name: "Test User", token: "sometoken")
      expect(user).to be_valid
    end

    it "is invalid without an email" do
      user = User.new(email: nil, nick_name: "Test User", token: "sometoken")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "is invalid without a nick_name" do
      user = User.new(email: "test@example.com", nick_name: nil, token: "sometoken")
      expect(user).not_to be_valid
      expect(user.errors[:nick_name]).to include("can't be blank")
    end

    it "is invalid with a duplicate email" do
      User.create!(email: "dup@example.com", nick_name: "User A", token: "token_a")
      user = User.new(email: "dup@example.com", nick_name: "User B", token: "token_b")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end
  end

  describe "token generation" do
    it "generates a token before create" do
      user = User.create!(email: "new@example.com", nick_name: "New User")
      expect(user.token).not_to be_nil
      expect(user.token.length).to be > 0
    end

    it "generates unique tokens" do
      user1 = User.create!(email: "a@example.com", nick_name: "User A")
      user2 = User.create!(email: "b@example.com", nick_name: "User B")
      expect(user1.token).not_to eq(user2.token)
    end
  end

  describe "associations" do
    it "has many topics" do
      expect(users(:user_one).topics).to include(topics(:one))
      expect(users(:user_one).topics).not_to include(topics(:two))
    end
  end
end
