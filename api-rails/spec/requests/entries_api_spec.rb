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

  # GET /api/v1/entries - read 필드 (이슈 #116)
  describe "GET /api/v1/entries - read 필드" do
    it "읽지 않은 entry는 read: false" do
      get_json "/api/v1/entries", login_user: users(:user_two)

      record = json_response["records"].find { |e| e["id"] == entries(:entry_in_topic_two).id }
      expect(record["read"]).to eq(false)
    end

    it "읽음 처리된 entry는 read: true" do
      EntryRead.create!(user: users(:user_two), entry: entries(:entry_in_topic_two), read_at: Time.current)

      get_json "/api/v1/entries", login_user: users(:user_two)

      record = json_response["records"].find { |e| e["id"] == entries(:entry_in_topic_two).id }
      expect(record["read"]).to eq(true)
    end
  end

  # POST /api/v1/entries/reads (이슈 #116)
  describe "POST /api/v1/entries/reads" do
    it "여러 entry를 한번에 읽음 처리한다" do
      expect {
        post_json "/api/v1/entries/reads",
                  login_user: users(:user_one),
                  params: { entry_ids: [entries(:entry_one).id, entries(:entry_two).id] }
      }.to change(EntryRead, :count).by(2)

      expect(response).to have_http_status(200)
      expect(json_response["marked"]).to match_array([entries(:entry_one).id, entries(:entry_two).id])
    end

    it "이미 읽은 entry는 중복 생성하지 않는다" do
      EntryRead.create!(user: users(:user_one), entry: entries(:entry_one), read_at: Time.current)

      expect {
        post_json "/api/v1/entries/reads",
                  login_user: users(:user_one),
                  params: { entry_ids: [entries(:entry_one).id, entries(:entry_two).id] }
      }.to change(EntryRead, :count).by(1)
    end

    it "구독하지 않는 토픽의 entry는 무시한다" do
      expect {
        post_json "/api/v1/entries/reads",
                  login_user: users(:user_two),
                  params: { entry_ids: [entries(:entry_one).id] } # user_two는 topics(:one)을 구독하지 않음
      }.not_to change(EntryRead, :count)

      expect(json_response["marked"]).to eq([])
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/entries/reads", params: { entry_ids: [entries(:entry_one).id] }
      expect(response).to have_http_status(401)
    end
  end

  # 생성/수정 시 자동 읽음 처리 및 알림 큐잉 (이슈 #116)
  describe "생성/수정 시 자동 읽음 처리 및 알림 큐잉" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "엔트리를 생성하면 작성자 본인은 자동으로 읽음 처리된다" do
      topic = topics(:one)

      post_json "/api/v1/entries",
                login_user: users(:user_one),
                params: { topic_id: topic.id, title: "New" }

      expect(json_response["read"]).to eq(true)
      expect(EntryRead.exists?(user: users(:user_one), entry_id: json_response["id"])).to be true
    end

    it "엔트리를 수정하면 수정자 본인은 자동으로 읽음 처리된다" do
      entry = entries(:entry_one)

      patch_json "/api/v1/entries/#{entry.id}",
                 login_user: users(:user_one),
                 params: { title: "Edited" }

      expect(json_response["read"]).to eq(true)
      expect(EntryRead.exists?(user: users(:user_one), entry_id: entry.id)).to be true
    end

    it "본인을 제외하고, 디바이스 토큰을 등록한 구독자에게만 알림 잡이 큐잉된다" do
      topic = topics(:one) # user_one 소유, guest_user·user_three가 구독
      DeviceToken.create!(user: users(:guest_user), token: "guest-device", platform: "ios")
      # user_three는 디바이스 토큰이 없으므로 알림 대상에서 제외된다

      expect {
        post_json "/api/v1/entries",
                  login_user: users(:user_one),
                  params: { topic_id: topic.id, title: "New" }
      }.to have_enqueued_job(SendPushJob).exactly(1).times
    end

    it "한 사용자의 디바이스 토큰마다 독립적인 알림 잡을 큐잉한다" do
      topic = topics(:one)
      DeviceToken.create!(user: users(:guest_user), token: "guest-ios", platform: "ios")
      DeviceToken.create!(user: users(:guest_user), token: "guest-android", platform: "android")

      expect {
        post_json "/api/v1/entries",
                  login_user: users(:user_one),
                  params: { topic_id: topic.id, title: "New" }
      }.to have_enqueued_job(SendPushJob).exactly(2).times
    end

    it "notifications_enabled가 꺼진 구독자에게는 알림을 큐잉하지 않는다" do
      topic = topics(:one)
      TopicFollow.find_by(user: users(:guest_user), topic: topic).update!(notifications_enabled: false)
      DeviceToken.create!(user: users(:guest_user), token: "guest-device", platform: "ios")
      TopicFollow.find_by(user: users(:user_three), topic: topic).update!(notifications_enabled: true)
      DeviceToken.create!(user: users(:user_three), token: "u3-device", platform: "android")

      expect {
        post_json "/api/v1/entries",
                  login_user: users(:user_one),
                  params: { topic_id: topic.id, title: "New" }
      }.to have_enqueued_job(SendPushJob).exactly(1).times
    end

    it "삭제 시에도 알림 잡이 큐잉된다" do
      entry = entries(:entry_one)
      DeviceToken.create!(user: users(:guest_user), token: "guest-device", platform: "ios")

      expect {
        delete_json "/api/v1/entries/#{entry.id}", login_user: users(:user_one)
      }.to have_enqueued_job(SendPushJob).exactly(1).times
    end
  end
end
