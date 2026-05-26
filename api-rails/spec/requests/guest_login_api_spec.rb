require "rails_helper"

RSpec.describe "GuestLogin API", type: :request do
  describe "POST /api/v1/guest_login" do
    let(:firebase_uid) { "firebase_uid_abc123" }
    let(:firebase_token) { "valid_firebase_token" }

    before do
      allow_any_instance_of(FirebaseTokenVerifier)
        .to receive(:verify!)
        .and_return(firebase_uid)
    end

    it "creates a new guest user and returns user token" do
      expect {
        post_json "/api/v1/guest_login", params: { firebase_token: firebase_token }
      }.to change(User, :count).by(1).and change(FirebaseToken, :count).by(1)

      expect(response).to have_http_status(200)
      expect(json_response["email"]).to eq("#{firebase_uid}@example.com")
      expect(json_response["token"]).not_to be_nil
      expect(json_response["nick_name"]).to eq("Guest")
    end

    it "returns existing user on subsequent login with same firebase token" do
      post_json "/api/v1/guest_login", params: { firebase_token: firebase_token }
      expect(response).to have_http_status(200)
      user_token = json_response["token"]

      expect {
        post_json "/api/v1/guest_login", params: { firebase_token: firebase_token }
      }.not_to change(User, :count)

      expect(response).to have_http_status(200)
      expect(json_response["token"]).to eq(user_token)
    end

    it "returns existing user when user already exists for the firebase uid" do
      User.create!(email: "#{firebase_uid}@example.com", nick_name: "Guest")

      expect {
        post_json "/api/v1/guest_login", params: { firebase_token: firebase_token }
      }.not_to change(User, :count)

      expect(response).to have_http_status(200)
      expect(json_response["email"]).to eq("#{firebase_uid}@example.com")
    end

    it "returns 400 when firebase_token param is missing" do
      post_json "/api/v1/guest_login", params: {}

      expect(response).to have_http_status(400)
    end

    it "returns 401 when firebase token is invalid" do
      allow_any_instance_of(FirebaseTokenVerifier)
        .to receive(:verify!)
        .and_raise(FirebaseTokenVerifier::VerificationError, "Invalid Firebase token")

      post_json "/api/v1/guest_login", params: { firebase_token: "bad_token" }

      expect(response).to have_http_status(401)
      expect(json_response["message"]).to include("Invalid Firebase token")
    end

    it "records last_failed_at on a known firebase token when verification fails" do
      user = users(:user_one)
      ft = FirebaseToken.create!(user: user, token: "known_bad_token")

      allow_any_instance_of(FirebaseTokenVerifier)
        .to receive(:verify!)
        .and_raise(FirebaseTokenVerifier::VerificationError, "Invalid Firebase token")

      post_json "/api/v1/guest_login", params: { firebase_token: "known_bad_token" }

      expect(response).to have_http_status(401)
      expect(ft.reload.last_failed_at).not_to be_nil
    end
  end
end
