require "rails_helper"

RSpec.describe "Users API", type: :request do
  describe "POST /api/v1/guest_login" do
    it "creates a guest user and returns a user token" do
      guest_token = "firebase-anon-123"

      expect {
        post_json "/api/v1/guest_login", params: { guest_token: guest_token }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(201)
      expect(json_response["email"]).to eq("#{guest_token}@example.com")
      expect(json_response["nick_name"]).to eq("Guest-#{guest_token.first(8)}")
      expect(json_response["is_guest"]).to eq(true)
      expect(json_response["token"]).to be_present
    end

    it "does not allow reusing a guest token" do
      guest_token = "firebase-anon-used"
      User.create!(email: "#{guest_token}@example.com", nick_name: "Guest", is_guest: true)

      expect {
        post_json "/api/v1/guest_login", params: { guest_token: guest_token }
      }.not_to change(User, :count)

      expect(response).to have_http_status(409)
      expect(json_response["message"]).to eq("Guest already registered")
    end
  end
end
