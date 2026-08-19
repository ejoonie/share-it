require "rails_helper"

RSpec.describe "MyDeviceTokens API", type: :request do
  # POST /api/v1/my/device_tokens
  describe "POST /api/v1/my/device_tokens" do
    it "registers a new device token for the current user" do
      expect {
        post_json "/api/v1/my/device_tokens",
                  login_user: users(:user_one),
                  params: { token: "new-fcm-token", platform: "ios" }
      }.to change(DeviceToken, :count).by(1)

      expect(response).to have_http_status(201)
      expect(DeviceToken.last.user).to eq(users(:user_one))
      expect(DeviceToken.last.platform).to eq("ios")
    end

    it "reassigns an existing token to the current user (e.g. device re-login as another account)" do
      existing = DeviceToken.create!(user: users(:user_two), token: "shared-token", platform: "android")

      expect {
        post_json "/api/v1/my/device_tokens",
                  login_user: users(:user_one),
                  params: { token: "shared-token", platform: "android" }
      }.not_to change(DeviceToken, :count)

      expect(existing.reload.user).to eq(users(:user_one))
    end

    it "returns 400 for an unsupported platform" do
      post_json "/api/v1/my/device_tokens",
                login_user: users(:user_one),
                params: { token: "x", platform: "windows" }

      expect(response).to have_http_status(400)
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/my/device_tokens", params: { token: "x", platform: "ios" }

      expect(response).to have_http_status(401)
    end
  end

  # DELETE /api/v1/my/device_tokens/:token
  describe "DELETE /api/v1/my/device_tokens/:token" do
    it "removes the token for the current user" do
      DeviceToken.create!(user: users(:user_one), token: "to-remove", platform: "ios")

      expect {
        delete_json "/api/v1/my/device_tokens/to-remove", login_user: users(:user_one)
      }.to change(DeviceToken, :count).by(-1)

      expect(response).to have_http_status(204)
    end

    it "does not remove another user's token" do
      DeviceToken.create!(user: users(:user_two), token: "not-mine", platform: "ios")

      expect {
        delete_json "/api/v1/my/device_tokens/not-mine", login_user: users(:user_one)
      }.not_to change(DeviceToken, :count)
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/my/device_tokens/whatever"

      expect(response).to have_http_status(401)
    end
  end
end
