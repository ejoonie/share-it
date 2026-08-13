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

  # POST /api/v1/entries
  describe "POST /api/v1/entries" do
    it "creates an entry when the follow has create permission" do
      topic = topics(:one)

      expect {
        post_json "/api/v1/entries",
                  login_user: users(:user_one),
                  params: { topic_id: topic.id, kind: "expense", amount: 500, title: "Dinner" }
      }.to change(Entry, :count).by(1)

      expect(response).to have_http_status(201)
      expect(json_response["topic_id"]).to eq(topic.id)
      expect(json_response["title"]).to eq("Dinner")
    end

    it "returns 403 when the follow lacks create permission" do
      topic = topics(:one) # guest_user follows this with edit-only permissions

      post_json "/api/v1/entries",
                login_user: users(:guest_user),
                params: { topic_id: topic.id, title: "Sneaky entry" }

      expect(response).to have_http_status(403)
    end

    it "returns 404 when the user does not follow the topic" do
      topic = topics(:one) # user_two neither owns nor follows this

      post_json "/api/v1/entries",
                login_user: users(:user_two),
                params: { topic_id: topic.id, title: "Should not work" }

      expect(response).to have_http_status(404)
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/entries", params: { topic_id: topics(:one).id }

      expect(response).to have_http_status(401)
    end
  end

  # GET /api/v1/entries/:id
  describe "GET /api/v1/entries/:id" do
    it "shows an entry from a followed (not owned) topic" do
      entry = entries(:entry_one) # topics(:one), guest_user follows it

      get_json "/api/v1/entries/#{entry.id}", login_user: users(:guest_user)

      expect(response).to have_http_status(200)
      expect(json_response["id"]).to eq(entry.id)
    end

    it "returns 404 for an entry in a topic the user does not follow" do
      entry = entries(:entry_one)

      get_json "/api/v1/entries/#{entry.id}", login_user: users(:user_two)

      expect(response).to have_http_status(404)
    end

    it "returns 404 for a soft-deleted entry" do
      entry = entries(:entry_deleted)

      get_json "/api/v1/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end
  end

  # PATCH /api/v1/entries/:id
  describe "PATCH /api/v1/entries/:id" do
    it "updates an entry when the follow has edit permission" do
      entry = entries(:entry_one) # guest_user follows topics(:one) with edit

      patch_json "/api/v1/entries/#{entry.id}",
                 login_user: users(:guest_user),
                 params: { title: "Updated by follower" }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Updated by follower")
      expect(json_response["updated_by_id"]).to eq(users(:guest_user).id)
    end

    it "returns 403 when the follow lacks edit permission" do
      entry = entries(:entry_one) # user_three follows topics(:one) with create-only

      patch_json "/api/v1/entries/#{entry.id}",
                 login_user: users(:user_three),
                 params: { title: "Should not work" }

      expect(response).to have_http_status(403)
    end

    it "returns 404 for an entry in a topic the user does not follow" do
      entry = entries(:entry_one)

      patch_json "/api/v1/entries/#{entry.id}",
                 login_user: users(:user_two),
                 params: { title: "Should not work" }

      expect(response).to have_http_status(404)
    end
  end

  # DELETE /api/v1/entries/:id
  describe "DELETE /api/v1/entries/:id" do
    it "soft deletes an entry when the follow has delete permission" do
      entry = entries(:entry_one) # user_one owns topics(:one), owner always has delete

      delete_json "/api/v1/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["deleted_at"]).not_to be_nil
      expect(Entry.find_by(id: entry.id)).to be_nil
    end

    it "returns 403 when the follow lacks delete permission" do
      entry = entries(:entry_one) # user_three follows topics(:one) with create-only

      delete_json "/api/v1/entries/#{entry.id}", login_user: users(:user_three)

      expect(response).to have_http_status(403)
      expect(Entry.find_by(id: entry.id)).not_to be_nil
    end

    it "returns 404 for an entry in a topic the user does not follow" do
      entry = entries(:entry_one)

      delete_json "/api/v1/entries/#{entry.id}", login_user: users(:user_two)

      expect(response).to have_http_status(404)
    end
  end
end
