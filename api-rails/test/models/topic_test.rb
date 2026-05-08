require "test_helper"

class TopicTest < ActiveSupport::TestCase
  test "valid topic" do
    topic = Topic.new(owner_id: "user_1", title: "My Topic", is_default: false)
    assert topic.valid?
  end

  test "title cannot be nil" do
    topic = Topic.new(owner_id: "user_1", title: nil, is_default: false)
    assert_not topic.valid?
    assert_includes topic.errors[:title], "can't be blank"
  end

  test "title cannot be empty string" do
    topic = Topic.new(owner_id: "user_1", title: "", is_default: false)
    assert_not topic.valid?
    assert_includes topic.errors[:title], "can't be blank"
  end

  test "title can contain spaces" do
    topic = Topic.new(owner_id: "user_1", title: "My Topic With Spaces", is_default: false)
    assert topic.valid?
  end

  test "owner_id cannot be nil" do
    topic = Topic.new(owner_id: nil, title: "My Topic", is_default: false)
    assert_not topic.valid?
    assert_includes topic.errors[:owner_id], "can't be blank"
  end

  test "default scope excludes soft deleted records" do
    assert_not_includes Topic.all, topics(:deleted)
    assert_includes Topic.all, topics(:one)
  end

  test "soft_delete! sets deleted_at" do
    topic = topics(:one)
    assert_nil topic.deleted_at
    topic.soft_delete!
    deleted = Topic.unscoped.find(topic.id)
    assert_not_nil deleted.deleted_at
  end

  test "soft deleted topics are excluded from default scope" do
    topic = topics(:one)
    topic.soft_delete!
    assert_nil Topic.find_by(id: topic.id)
  end
end
