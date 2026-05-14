require "rails_helper"

RSpec.describe "MyTopics API", type: :request do
  # GET /api/v1/my/topics/owned
  describe "GET /api/v1/my/topics/owned" do
    it "lists owned topics" do
      get_json "/api/v1/my/topics/owned", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      topic_titles = json_response["records"].map { |t| t["title"] }
      expect(json_response["total"]).to be_a(Integer)
      expect(topic_titles).to include("First Topic")
      expect(topic_titles).not_to include("Second Topic")
      expect(topic_titles).not_to include("Deleted Topic")
    end
  end

  # GET /api/v1/my/topics/subscribed
  describe "GET /api/v1/my/topics/subscribed" do
    it "lists subscribed topics" do
      topic = topics(:two)

      expect {
        users(:user_one).follow(topic)
      }.to change {
        get_json "/api/v1/my/topics/subscribed", login_user: users(:user_one)
        json_response["total"]
      }.by(1)
    end
  end

  # GET /api/v1/my/topics/:id
  describe "GET /api/v1/my/topics/:id" do
    it "shows a topic" do
      topic = topics(:one)
      get_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["id"]).to eq(topic.id)
      expect(json_response["title"]).to eq("First Topic")
    end

    it "returns 404 for non-existent topic" do
      get_json "/api/v1/my/topics/999999", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 for soft-deleted topic on show" do
      topic = topics(:deleted)
      get_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 for topic owned by another user" do
      topic = topics(:two)
      get_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end
  end

  # GET /api/v1/my/topics/:id/follows
  describe "GET /api/v1/my/topics/:id/follows" do
    it "lists topic follows for owner" do
      topic = topics(:one)

      get_json "/api/v1/my/topics/#{topic.id}/follows", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["total"]).to be >= 1
      first_record = json_response["records"].first
      expect(first_record).to include("permissions", "user")
      expect(first_record["user"]).to include("id", "email", "nick_name")
    end

    it "returns 403 when non-owner requests follow list" do
      topic = topics(:one)

      get_json "/api/v1/my/topics/#{topic.id}/follows", login_user: users(:user_two)

      expect(response).to have_http_status(404)
    end
  end

  # POST /api/v1/my/topics/:id/invitations
  describe "POST /api/v1/my/topics/:id/invitations" do
    it "invites a follower by email" do
      topic = topics(:one)

      post_json "/api/v1/my/topics/#{topic.id}/invitations",
                login_user: users(:user_one),
                params: { people: [{ email: "user2@example.com", permissions: %w[create admin] }] }

      expect(response).to have_http_status(201)
      expect(json_response["total"]).to eq(1)
      record = json_response["records"].first
      expect(record["permissions"]).to eq(%w[create admin])
      expect(record["invited_at"]).not_to be_nil
      expect(record["user"]["email"]).to eq("user2@example.com")
    end

    it "creates users when invited user does not exist" do
      topic = topics(:one)

      expect {
        post_json "/api/v1/my/topics/#{topic.id}/invitations",
                  login_user: users(:user_one),
                  params: { people: [{ email: "missing@example.com", permissions: %w[create] }] }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(201)
    end

    it "uses topic default_permissions when permissions are omitted" do
      topic = topics(:one)

      post_json "/api/v1/my/topics/#{topic.id}/invitations",
                login_user: users(:user_one),
                params: { people: [{ email: "new_default_permissions_user@example.com" }] }

      expect(response).to have_http_status(201)
      expect(json_response["records"].first["permissions"]).to eq(%w[create edit])
    end
  end

  # PUT /api/v1/my/topics/:id/follows/:follow_id
  describe "PUT /api/v1/my/topics/:id/follows/:follow_id" do
    it "updates follow permissions" do
      topic = topics(:one)
      follow = topic_follows(:one)

      put_json "/api/v1/my/topics/#{topic.id}/follows/#{follow.id}",
               login_user: users(:user_one),
               params: { permissions: %w[create edit admin] }

      expect(response).to have_http_status(200)
      expect(json_response["permissions"]).to eq(%w[create edit admin])
    end

    it "returns 403 when non-owner updates permissions" do
      topic = topics(:one)
      follow = topic_follows(:one)

      put_json "/api/v1/my/topics/#{topic.id}/follows/#{follow.id}",
               login_user: users(:user_two),
               params: { permissions: %w[create] }

      expect(response).to have_http_status(404)
    end
  end

  # PATCH /api/v1/my/topics/:id
  describe "PATCH /api/v1/my/topics/:id" do
    it "updates a topic title" do
      topic = topics(:one)
      patch_json "/api/v1/my/topics/#{topic.id}",
                 login_user: users(:user_one),
                 params: { title: "Updated Title" }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Updated Title")
    end

    it "strips whitespace from title on update" do
      topic = topics(:one)
      patch_json "/api/v1/my/topics/#{topic.id}",
                 login_user: users(:user_one),
                 params: { title: "  Trimmed  " }

      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq("Trimmed")
    end

    it "returns 403 when updating topic owned by another user" do
      topic = topics(:two)
      patch_json "/api/v1/my/topics/#{topic.id}",
                 login_user: users(:user_one),
                 params: { title: "Hacked" }

      expect(response).to have_http_status(403)
    end

    it "returns 404 when updating non-existent topic" do
      patch_json "/api/v1/my/topics/999999",
                 login_user: users(:user_one),
                 params: { title: "New Title" }

      expect(response).to have_http_status(404)
    end

    it "returns 400 when title is blank on update" do
      topic = topics(:one)
      patch_json "/api/v1/my/topics/#{topic.id}",
                 login_user: users(:user_one),
                 params: { title: "   " }

      expect(response).to have_http_status(400)
    end
  end

  # DELETE /api/v1/my/topics/:id
  describe "DELETE /api/v1/my/topics/:id" do
    it "soft deletes a topic" do
      topic = topics(:one)
      delete_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(200)
      expect(json_response["deleted_at"]).not_to be_nil
      expect(Topic.find_by(id: topic.id)).to be_nil
    end

    it "returns 403 when deleting topic owned by another user" do
      topic = topics(:two)
      delete_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(403)
    end

    it "returns 404 when deleting non-existent topic" do
      delete_json "/api/v1/my/topics/999999", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end

    it "returns 404 when deleting already soft-deleted topic" do
      topic = topics(:deleted)
      delete_json "/api/v1/my/topics/#{topic.id}", login_user: users(:user_one)

      expect(response).to have_http_status(404)
    end
  end
end
