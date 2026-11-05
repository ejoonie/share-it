require 'rails_helper'

RSpec.describe 'Entry messages API', type: :request do
  let(:entry) { entries(:entry_one) }
  let(:owner) { users(:user_one) }
  let(:follower) { users(:user_three) }
  let(:path) { "/api/v1/entries/#{entry.id}/messages" }
  let!(:message) { entry.entry_messages.create!(user: owner, body: 'Where is this?') }

  it 'allows a follower to chat without entry edit permission and exposes only public author fields' do
    post_json path, login_user: follower, params: { body: '  Nice coffee!  ', user_id: owner.id }
    expect(response).to have_http_status(201)
    expect(json_response['body']).to eq('Nice coffee!')
    expect(json_response['author']).to eq('id' => follower.id, 'nick_name' => follower.nick_name)
    expect(EntryMessage.last.user).to eq(follower)
  end

  it 'paginates without overlaps when a new message arrives between pages' do
    newer = entry.entry_messages.create!(user: follower, body: 'Newer')
    entries(:entry_in_topic_two).entry_messages.create!(user: users(:user_two), body: 'Private')
    get_json "#{path}?limit=1", login_user: owner
    expect(response).to have_http_status(200)
    expect(json_response['records'].map { |r| r['id'] }).to eq([newer.id])
    expect(json_response['has_more']).to be(true)
    cursor = json_response['next_before_id']
    entry.entry_messages.create!(user: owner, body: 'Just arrived')
    get_json "#{path}?limit=1&before_id=#{cursor}", login_user: owner
    expect(json_response['records'].map { |r| r['id'] }).to eq([message.id])
    expect(json_response['has_more']).to be(false)
    expect(json_response['next_before_id']).to be_nil
  end

  it 'returns an empty page after the oldest message' do
    get_json "#{path}?before_id=#{message.id}", login_user: owner
    expect(json_response).to eq('records' => [], 'has_more' => false, 'next_before_id' => nil)
  end

  it 'allows only the author to edit and permanently delete a message' do
    patch_json "#{path}/#{message.id}", login_user: owner, params: { body: 'Updated' }
    expect(response).to have_http_status(200)
    expect(message.reload.body).to eq('Updated')
    delete_json "#{path}/#{message.id}", login_user: owner
    expect(response).to have_http_status(204)
    expect(EntryMessage.exists?(message.id)).to be(false)
  end

  it 'does not let a topic owner modify another author’s message' do
    message.update!(user: follower)
    patch_json "#{path}/#{message.id}", login_user: owner, params: { body: 'Overwrite' }
    expect(response).to have_http_status(403)
    delete_json "#{path}/#{message.id}", login_user: owner
    expect(response).to have_http_status(403)
    expect(message.reload.body).to eq('Where is this?')
  end

  it 'scopes message IDs to the requested entry' do
    other = entries(:entry_two).entry_messages.create!(user: owner, body: 'Other entry')
    patch_json "#{path}/#{other.id}", login_user: owner, params: { body: 'Overwrite' }
    expect(response).to have_http_status(404)
    delete_json "#{path}/#{other.id}", login_user: owner
    expect(response).to have_http_status(404)
  end

  [nil, :user_two, :guest_user].each do |user_key|
    it "rejects all operations for #{user_key || 'anonymous'}" do
      actor = user_key && users(user_key)
      expected = user_key == :user_two ? 404 : 401
      get_json path, login_user: actor
      expect(response).to have_http_status(expected)
      post_json path, login_user: actor, params: { body: 'Hello' }
      expect(response).to have_http_status(expected)
      patch_json "#{path}/#{message.id}", login_user: actor, params: { body: 'Hello' }
      expect(response).to have_http_status(expected)
      delete_json "#{path}/#{message.id}", login_user: actor
      expect(response).to have_http_status(expected)
    end
  end

  [:banned, :unfollowed, :deleted_entry, :deleted_topic].each do |state|
    it "blocks all operations when #{state}, even for the message author" do
      message.update!(user: follower)
      follow = follower.topic_follows.find_by!(topic: entry.topic)
      case state
      when :banned then follow.update!(permissions: %w[create banned])
      when :unfollowed then follow.destroy!
      when :deleted_entry then entry.soft_delete!
      when :deleted_topic then entry.topic.soft_delete!
      end
      expected = state == :banned ? 403 : 404
      get_json path, login_user: follower
      expect(response).to have_http_status(expected)
      post_json path, login_user: follower, params: { body: 'Hello' }
      expect(response).to have_http_status(expected)
      patch_json "#{path}/#{message.id}", login_user: follower, params: { body: 'Hello' }
      expect(response).to have_http_status(expected)
      delete_json "#{path}/#{message.id}", login_user: follower
      expect(response).to have_http_status(expected)
    end
  end

  [nil, '', '   ', 'a' * 2001].each do |body|
    it "rejects invalid body of length #{body&.length.inspect} on create and edit" do
      expect { post_json path, login_user: owner, params: { body: body } }.not_to change(EntryMessage, :count)
      expect([400, 422]).to include(response.status)
      patch_json "#{path}/#{message.id}", login_user: owner, params: { body: body }
      expect([400, 422]).to include(response.status)
      expect(message.reload.body).to eq('Where is this?')
    end
  end

  it 'accepts the maximum message length including Unicode' do
    post_json path, login_user: owner, params: { body: '가' * 2000 }
    expect(response).to have_http_status(201)
  end

  ['limit=0', 'limit=101', 'before_id=-1', 'before_id=nope'].each do |query|
    it "rejects invalid pagination: #{query}" do
      get_json "#{path}?#{query}", login_user: owner
      expect(response).to have_http_status(400)
    end
  end

  it 'cleans messages in owned soft-deleted topics during account deletion' do
    entry.entry_messages.create!(user: follower, body: 'Someone else wrote this')
    entry.soft_delete!
    entry.topic.soft_delete!
    expect { owner.delete_with_data! }.not_to raise_error
    expect(EntryMessage.where(entry_id: entry.id)).to be_empty
  end

  it 'cleans an author’s messages while preserving another user’s entry on account deletion' do
    message.update!(user: follower)
    follower.delete_with_data!
    expect(EntryMessage.exists?(message.id)).to be(false)
    expect(Entry.exists?(entry.id)).to be(true)
  end
end
