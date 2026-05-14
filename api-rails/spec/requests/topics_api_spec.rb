require "rails_helper"

RSpec.describe "Topics API", type: :request do
  # GET /api/v1/topics/:token
  describe "GET /api/v1/topics/:token" do
    it "shows a topic" do
      topic = topics(:one)
      get "/api/v1/topics/#{topic.token}",
          headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(200)
      expect(json_response["id"]).to eq(topic.id)
      expect(json_response["title"]).to eq("First Topic")
    end

    it "returns 404 for non-existent topic" do
      get "/api/v1/topics/xxxxx",
          headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(404)
    end

    it "returns 404 for soft-deleted topic on show" do
      topic = topics(:deleted)
      get "/api/v1/topics/#{topic.token}",
          headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(404)
    end
  end

  # POST /api/v1/topics/:id/follow
  describe "POST /api/v1/topics/:token/follow" do
    it "creates a follow for current user" do
      topic = topics(:two)

      post_json "/api/v1/topics/#{topic.token}/follow"

      expect(response).to have_http_status(201)
      expect(json_response["topic_id"]).to eq(topic.id)
      expect(json_response["user_id"]).to eq(users(:user_one).id)
      expect(json_response["permissions"]).to eq(%w[create edit])
      expect(json_response["followed_at"]).not_to be_nil
    end

    it "does nothing when already followed" do
      follow = topic_follows(:one)
      original_followed_at = follow.followed_at
      original_permissions = follow.permissions

      post_json "/api/v1/topics/#{follow.topic.token}/follow"

      expect(response).to have_http_status(200)
      follow.reload
      expect(follow.followed_at).to eq(original_followed_at)
      expect(follow.permissions).to eq(original_permissions)
    end

    it "returns 404 for non-existent topic" do
      post_json "/api/v1/topics/999999/follow"

      expect(response).to have_http_status(404)
    end
  end
end
