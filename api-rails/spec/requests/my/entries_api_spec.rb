require "rails_helper"

RSpec.describe "MyEntries API", type: :request do
  # POST /api/v1/my/topics/:topic_id/entries
  describe "POST /api/v1/my/topics/:topic_id/entries" do
    it "creates an entry" do
      topic = topics(:one)

      expect {
        post_json "/api/v1/my/topics/#{topic.id}/entries",
                  login_user: users(:user_one),
                  params: {
                    kind: "expense",
                    currency: "usd",
                    amount: 500,
                    category: "food",
                    title: "Dinner",
                    content: "Team dinner",
                    checked: false
                  }
      }.to change(Entry, :count).by(1)

      expect(response).to have_http_status(201)
      expect(json_response["kind"]).to eq("expense")
      expect(json_response["amount"]).to eq(500)
      expect(json_response["title"]).to eq("Dinner")
      expect(json_response["created_by_id"]).to eq(users(:user_one).id)
      expect(json_response["updated_by_id"]).to eq(users(:user_one).id)
    end

    it "creates an entry with default values" do
      topic = topics(:one)

      post_json "/api/v1/my/topics/#{topic.id}/entries",
                login_user: users(:user_one),
                params: {}

      expect(response).to have_http_status(201)
      expect(json_response["currency"]).to eq("usd")
      expect(json_response["amount"]).to eq(0)
      expect(json_response["checked"]).to eq(false)
    end

    it "returns 404 when topic does not exist" do
      post_json "/api/v1/my/topics/999999/entries",
                login_user: users(:user_one),
                params: { title: "Test" }

      expect(response).to have_http_status(404)
    end

    it "returns 404 when topic belongs to another user" do
      other_topic = topics(:two)

      post_json "/api/v1/my/topics/#{other_topic.id}/entries",
                login_user: users(:user_one),
                params: { title: "Sneaky entry" }

      expect(response).to have_http_status(404)
    end

    it "returns 401 when not authenticated" do
      topic = topics(:one)
      post "/api/v1/my/topics/#{topic.id}/entries"

      expect(response).to have_http_status(401)
    end
  end

  # GET /api/v1/my/topics/:topic_id/entries
  describe "GET /api/v1/my/topics/:topic_id/entries" do
    it "lists entries for a topic" do
      topic = topics(:one)
      get_json "/api/v1/my/topics/#{topic.id}/entries", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["total"]).to be_a(Integer)
      expect(json_response["records"]).to be_an(Array)
    end

    it "does not include soft-deleted entries" do
      topic = topics(:one)
      get_json "/api/v1/my/topics/#{topic.id}/entries", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      ids = json_response["records"].map { |e| e["id"] }
      expect(ids).not_to include(entries(:entry_deleted).id)
    end

    it "returns 404 when topic does not exist" do
      get_json "/api/v1/my/topics/999999/entries", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 when topic belongs to another user" do
      other_topic = topics(:two)
      get_json "/api/v1/my/topics/#{other_topic.id}/entries", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    context "with ransack search params" do
      it "filters entries by kind" do
        topic = topics(:one)
        get_json "/api/v1/my/topics/#{topic.id}/entries?q[kind_eq]=expense",
                 login_user: users(:user_one)

        expect(response).to have_http_status(200)
        expect(json_response["records"]).to all(include("kind" => "expense"))
      end

      it "filters entries by title containing a string" do
        topic = topics(:one)
        get_json "/api/v1/my/topics/#{topic.id}/entries?q[title_cont]=Lunch",
                 login_user: users(:user_one)

        expect(response).to have_http_status(200)
        expect(json_response["records"]).to all(satisfy { |e| e["title"].to_s.include?("Lunch") })
      end

      it "filters entries by minimum amount" do
        topic = topics(:one)
        get_json "/api/v1/my/topics/#{topic.id}/entries?q[amount_gteq]=5000",
                 login_user: users(:user_one)

        expect(response).to have_http_status(200)
        expect(json_response["records"]).to all(satisfy { |e| e["amount"] >= 5000 })
      end

      it "filters entries by checked status" do
        topic = topics(:one)
        get_json "/api/v1/my/topics/#{topic.id}/entries?q[checked_eq]=true",
                 login_user: users(:user_one)

        expect(response).to have_http_status(200)
        expect(json_response["records"]).to all(include("checked" => true))
      end

      it "sorts entries by amount ascending when s param is given" do
        topic = topics(:one)
        get_json "/api/v1/my/topics/#{topic.id}/entries?q[s]=amount+asc",
                 login_user: users(:user_one)

        expect(response).to have_http_status(200)
        amounts = json_response["records"].map { |e| e["amount"] }
        expect(amounts).to eq(amounts.sort)
      end
    end
  end

  # GET /api/v1/my/topics/:topic_id/entries/:id
  describe "GET /api/v1/my/topics/:topic_id/entries/:id" do
    it "shows an entry" do
      topic = topics(:one)
      entry = entries(:entry_one)

      get_json "/api/v1/my/topics/#{topic.id}/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["id"]).to eq(entry.id)
      expect(json_response["title"]).to eq("Lunch")
    end

    it "returns 404 for non-existent entry" do
      topic = topics(:one)
      get_json "/api/v1/my/topics/#{topic.id}/entries/999999", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 for soft-deleted entry" do
      topic = topics(:one)
      entry = entries(:entry_deleted)

      get_json "/api/v1/my/topics/#{topic.id}/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 when topic belongs to another user" do
      other_topic = topics(:two)
      entry = entries(:entry_in_topic_two)

      get_json "/api/v1/my/topics/#{other_topic.id}/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end
  end

  # PATCH /api/v1/my/topics/:topic_id/entries/:id
  describe "PATCH /api/v1/my/topics/:topic_id/entries/:id" do
    it "updates an entry and sets updated_by to current user" do
      topic = topics(:one)
      entry = entries(:entry_one)
      login_user = users(:user_one)
      entry.update(topic: topic)

      patch_json "/api/v1/my/topics/#{topic.id}/entries/#{entry.id}",
                 login_user: login_user,
                 params: { title: "Updated Title", amount: 999 }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Updated Title")
      expect(json_response["amount"]).to eq(999)
      expect(json_response["updated_by_id"]).to eq(login_user.id)
    end

    it "returns 404 for non-existent entry" do
      topic = topics(:one)
      patch_json "/api/v1/my/topics/#{topic.id}/entries/999999",
                 login_user: users(:user_one),
                 params: { title: "New Title" }

      expect(response).to have_http_status(404)
    end

    it "returns 404 when topic belongs to another user" do
      other_topic = topics(:two)
      entry = entries(:entry_in_topic_two)

      patch_json "/api/v1/my/topics/#{other_topic.id}/entries/#{entry.id}",
                 login_user: users(:user_one),
                 params: { title: "Hacked" }

      expect(response).to have_http_status(404)
    end
  end

  # DELETE /api/v1/my/topics/:topic_id/entries/:id
  describe "DELETE /api/v1/my/topics/:topic_id/entries/:id" do
    it "soft deletes an entry" do
      topic = topics(:one)
      entry = entries(:entry_one)

      delete_json "/api/v1/my/topics/#{topic.id}/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["deleted_at"]).not_to be_nil
      expect(Entry.find_by(id: entry.id)).to be_nil
    end

    it "returns 404 for non-existent entry" do
      topic = topics(:one)
      delete_json "/api/v1/my/topics/#{topic.id}/entries/999999", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 when deleting already soft-deleted entry" do
      topic = topics(:one)
      entry = entries(:entry_deleted)

      delete_json "/api/v1/my/topics/#{topic.id}/entries/#{entry.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 when topic belongs to another user" do
      other_topic = topics(:two)
      entry = entries(:entry_in_topic_two)

      delete_json "/api/v1/my/topics/#{other_topic.id}/entries/#{entry.id}",
                  login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end
  end
end
