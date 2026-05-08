require "test_helper"

class TopicsAPITest < ActionDispatch::IntegrationTest
  def json_response
    JSON.parse(response.body)
  end

  # POST /api/v1/topics
  test "creates a topic" do
    post "/api/v1/topics",
      params: { title: "New Topic" }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 201, response.status
    assert_equal "New Topic", json_response["title"]
    assert_equal "user_1", json_response["owner_id"]
    assert_nil json_response["deleted_at"]
  end

  test "returns 400 when title is missing on create" do
    post "/api/v1/topics",
      params: {}.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 400, response.status
  end

  test "returns 400 when title is blank on create" do
    post "/api/v1/topics",
      params: { title: "   " }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 400, response.status
  end

  test "returns 401 when x-user-id header is missing on create" do
    post "/api/v1/topics",
      params: { title: "New Topic" }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_equal 401, response.status
  end

  # GET /api/v1/topics/owned
  test "lists owned topics" do
    get "/api/v1/topics/owned",
      headers: { "x-user-id" => "user_1" }

    assert_equal 200, response.status
    topic_titles = json_response["topics"].map { |t| t["title"] }
    assert_includes topic_titles, "First Topic"
    assert_not_includes topic_titles, "Second Topic"
    assert_not_includes topic_titles, "Deleted Topic"
  end

  # GET /api/v1/topics/:id
  test "shows a topic" do
    topic = topics(:one)
    get "/api/v1/topics/#{topic.id}",
      headers: { "x-user-id" => "user_1" }

    assert_equal 200, response.status
    assert_equal topic.id, json_response["id"]
    assert_equal "First Topic", json_response["title"]
  end

  test "returns 404 for non-existent topic" do
    get "/api/v1/topics/999999",
      headers: { "x-user-id" => "user_1" }

    assert_equal 404, response.status
  end

  test "returns 404 for soft-deleted topic on show" do
    topic = topics(:deleted)
    get "/api/v1/topics/#{topic.id}",
      headers: { "x-user-id" => "user_1" }

    assert_equal 404, response.status
  end

  # PATCH /api/v1/topics/:id
  test "updates a topic title" do
    topic = topics(:one)
    patch "/api/v1/topics/#{topic.id}",
      params: { title: "Updated Title" }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 200, response.status
    assert_equal "Updated Title", json_response["title"]
  end

  test "strips whitespace from title on update" do
    topic = topics(:one)
    patch "/api/v1/topics/#{topic.id}",
      params: { title: "  Trimmed  " }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 200, response.status
    assert_equal "Trimmed", json_response["title"]
  end

  test "returns 403 when updating topic owned by another user" do
    topic = topics(:two)
    patch "/api/v1/topics/#{topic.id}",
      params: { title: "Hacked" }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 403, response.status
  end

  test "returns 404 when updating non-existent topic" do
    patch "/api/v1/topics/999999",
      params: { title: "New Title" }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 404, response.status
  end

  test "returns 400 when title is blank on update" do
    topic = topics(:one)
    patch "/api/v1/topics/#{topic.id}",
      params: { title: "   " }.to_json,
      headers: { "Content-Type" => "application/json", "x-user-id" => "user_1" }

    assert_equal 400, response.status
  end

  # DELETE /api/v1/topics/:id
  test "soft deletes a topic" do
    topic = topics(:one)
    delete "/api/v1/topics/#{topic.id}",
      headers: { "x-user-id" => "user_1" }

    assert_equal 200, response.status
    assert_not_nil json_response["deleted_at"]
    assert_nil Topic.find_by(id: topic.id)
  end

  test "returns 403 when deleting topic owned by another user" do
    topic = topics(:two)
    delete "/api/v1/topics/#{topic.id}",
      headers: { "x-user-id" => "user_1" }

    assert_equal 403, response.status
  end

  test "returns 404 when deleting non-existent topic" do
    delete "/api/v1/topics/999999",
      headers: { "x-user-id" => "user_1" }

    assert_equal 404, response.status
  end

  test "returns 404 when deleting already soft-deleted topic" do
    topic = topics(:deleted)
    delete "/api/v1/topics/#{topic.id}",
      headers: { "x-user-id" => "user_1" }

    assert_equal 404, response.status
  end
end
