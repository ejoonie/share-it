require "rails_helper"

RSpec.describe "Entries API", type: :request do
  # GET /api/v1/entries
  describe "GET /api/v1/entries" do
    it "lists entries from all topics the user owns (owner is always a follower)" do
      get_json "/api/v1/entries", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      ids = json_response["records"].map { |e| e["id"] }
      expect(ids).to include(entries(:entry_one).id, entries(:entry_two).id)
      expect(ids).not_to include(entries(:entry_deleted).id, entries(:entry_in_topic_two).id)
    end

    it "includes entries from topics the user follows, in addition to owned topics" do
      get_json "/api/v1/entries", login_user: users(:guest_user)

      expect(response).to have_http_status(200)
      ids = json_response["records"].map { |e| e["id"] }
      # guest_user owns guest_topic and follows topics(:one)
      expect(ids).to include(entries(:guest_entry).id, entries(:entry_one).id, entries(:entry_two).id)
      expect(ids).not_to include(entries(:entry_in_topic_two).id)
    end

    it "filters via q[topic_id_in], intersected with followed topics" do
      get_json "/api/v1/entries?q[topic_id_in][]=#{topics(:one).id}", login_user: users(:guest_user)

      expect(response).to have_http_status(200)
      ids = json_response["records"].map { |e| e["id"] }
      expect(ids).to include(entries(:entry_one).id, entries(:entry_two).id)
      expect(ids).not_to include(entries(:guest_entry).id)
    end

    it "ignores topic ids the user does not follow" do
      get_json "/api/v1/entries?q[topic_id_in][]=#{topics(:two).id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["records"]).to eq([])
    end

    it "supports other ransack filters combined with topic scoping" do
      get_json "/api/v1/entries?q[kind_eq]=income", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["records"]).to all(include("kind" => "income"))
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/entries"

      expect(response).to have_http_status(401)
    end
  end
end
