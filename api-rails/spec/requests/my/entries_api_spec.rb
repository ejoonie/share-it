require "rails_helper"

RSpec.describe "MyEntries API", type: :request do
  # GET /api/v1/my/topics/:topic_id/entries
  # 생성/조회(단건)/수정/삭제는 V1::EntriesAPI(/api/v1/entries)로 옮겨졌다.
  # 이 목록 조회만 topic_id로 미리 좁혀서 보는 용도(쇼핑리스트)로 남아 있다.
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

    it "returns 401 when not authenticated" do
      topic = topics(:one)
      get "/api/v1/my/topics/#{topic.id}/entries"

      expect(response).to have_http_status(401)
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
end
