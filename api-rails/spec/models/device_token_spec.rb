require "rails_helper"

RSpec.describe DeviceToken, type: :model do
  it "is valid with a token and platform" do
    dt = DeviceToken.new(user: users(:user_one), token: "abc123", platform: "ios")
    expect(dt).to be_valid
  end

  it "requires a unique token" do
    DeviceToken.create!(user: users(:user_one), token: "dup-token", platform: "ios")
    dup = DeviceToken.new(user: users(:user_two), token: "dup-token", platform: "android")

    expect(dup).not_to be_valid
  end

  it "only allows ios or android as platform" do
    dt = DeviceToken.new(user: users(:user_one), token: "xyz", platform: "windows")

    expect(dt).not_to be_valid
  end
end
