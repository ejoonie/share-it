require "rails_helper"

RSpec.describe "Topics API", type: :request do

  # POST /api/v1/topics
  describe "POST /api/v1/topics" do
    it "creates a topic" do
      post_json "/api/v1/topics", params: { title: "New Topic" }

      expect(response).to have_http_status(201)
      expect(json_response["title"]).to eq("New Topic")
      expect(json_response["user_id"]).to eq(users(:user_one).id)
      expect(json_response["deleted_at"]).to be_nil
    end

    it "returns 400 when title is missing on create" do
      post_json "/api/v1/topics", params: {}

      expect(response).to have_http_status(400)
    end

    it "returns 400 when title is blank on create" do
      post_json "/api/v1/topics", params: { title: "   " }

      expect(response).to have_http_status(400)
    end

    it "returns 401 when x-token header is missing on create" do
      post "/api/v1/topics",
        params: { title: "New Topic" }.to_json,
        headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(401)
    end
  end

  # GET /api/v1/topics/owned
  describe "GET /api/v1/topics/owned" do
    it "lists owned topics" do
      get "/api/v1/topics/owned",
        headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(200)
      topic_titles = json_response["topics"].map { |t| t["title"] }
      expect(topic_titles).to include("First Topic")
      expect(topic_titles).not_to include("Second Topic")
      expect(topic_titles).not_to include("Deleted Topic")
    end
  end

  # GET /api/v1/topics/:id
  describe "GET /api/v1/topics/:id" do
    it "shows a topic" do
      topic = topics(:one)
      get "/api/v1/topics/#{topic.id}",
        headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(200)
      expect(json_response["id"]).to eq(topic.id)
      expect(json_response["title"]).to eq("First Topic")
    end

    it "returns 404 for non-existent topic" do
      get "/api/v1/topics/999999",
        headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(404)
    end

    it "returns 404 for soft-deleted topic on show" do
      topic = topics(:deleted)
      get "/api/v1/topics/#{topic.id}",
        headers: { "x-token" => "token_user_one" }

      expect(response).to have_http_status(404)
    end
  end

  # PATCH /api/v1/topics/:id
  describe "PATCH /api/v1/topics/:id" do
    it "updates a topic title" do
      topic = topics(:one)
      patch_json "/api/v1/topics/#{topic.id}",
        params: { title: "Updated Title" }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Updated Title")
    end

    it "strips whitespace from title on update" do
      topic = topics(:one)
      patch_json "/api/v1/topics/#{topic.id}",
        params: { title: "  Trimmed  " }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Trimmed")
    end

    it "returns 403 when updating topic owned by another user" do
      topic = topics(:two)
      patch_json "/api/v1/topics/#{topic.id}",
        params: { title: "Hacked" }

      expect(response).to have_http_status(403)
    end

    it "returns 404 when updating non-existent topic" do
      patch_json "/api/v1/topics/999999",
        params: { title: "New Title" }

      expect(response).to have_http_status(404)
    end

    it "returns 400 when title is blank on update" do
      topic = topics(:one)
      patch_json "/api/v1/topics/#{topic.id}",
        params: { title: "   " }

      expect(response).to have_http_status(400)
    end
  end

  # DELETE /api/v1/topics/:id
  describe "DELETE /api/v1/topics/:id" do
    it "soft deletes a topic" do
      topic = topics(:one)
      delete_json "/api/v1/topics/#{topic.id}"

      expect(response).to have_http_status(200)
      expect(json_response["deleted_at"]).not_to be_nil
      expect(Topic.find_by(id: topic.id)).to be_nil
    end

    it "returns 403 when deleting topic owned by another user" do
      topic = topics(:two)
      delete_json "/api/v1/topics/#{topic.id}"

      expect(response).to have_http_status(403)
    end

    it "returns 404 when deleting non-existent topic" do
      delete_json "/api/v1/topics/999999"

      expect(response).to have_http_status(404)
    end

    it "returns 404 when deleting already soft-deleted topic" do
      topic = topics(:deleted)
      delete_json "/api/v1/topics/#{topic.id}"

      expect(response).to have_http_status(404)
    end
  end
end

