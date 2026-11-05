require 'rails_helper'

RSpec.describe 'Chat realtime', type: :request do
  let(:entry) { entries(:entry_one) }
  let(:path) { "/api/v1/entries/#{entry.id}/messages" }
  let(:stream) { "entry_chat_#{entry.id}" }

  it 'issues a scoped connection ticket only to a follower' do
    post_json "#{path}/connection_ticket", login_user: users(:user_one)
    expect(response).to have_http_status(201)
    payload = Rails.application.message_verifier(:chat_connection).verified(json_response['ticket'], purpose: :chat_connection)
    expect(payload['entry_id']).to eq(entry.id)
    post_json "#{path}/connection_ticket", login_user: users(:user_two)
    expect(response).to have_http_status(404)
    post_json "#{path}/connection_ticket"
    expect(response).to have_http_status(401)
  end

  it 'broadcasts invalidations on create, edit and delete without message content' do
    expect(ActionCable.server).to receive(:broadcast).with(stream, hash_including(type: 'changed', message_id: kind_of(Integer))).exactly(3).times
    post_json path, login_user: users(:user_one), params: { body: 'Hello' }
    id = json_response['id']
    patch_json "#{path}/#{id}", login_user: users(:user_one), params: { body: 'Updated' }
    delete_json "#{path}/#{id}", login_user: users(:user_one)
    expect(response).to have_http_status(204)
  end

  it 'distinguishes a missing message from loss of entry access' do
    message = entry.entry_messages.create!(user: users(:user_one), body: 'Hello')
    get_json "#{path}/#{message.id}", login_user: users(:user_one)
    expect(response).to have_http_status(200)
    expect(json_response['body']).to eq('Hello')
    message.destroy!
    get_json "#{path}/#{message.id}", login_user: users(:user_one)
    expect(response).to have_http_status(404)
    expect(json_response['code']).to eq('message_not_found')
    get_json "#{path}/#{message.id}", login_user: users(:user_two)
    expect(response).to have_http_status(404)
    expect(json_response['code']).not_to eq('message_not_found')
  end

  it 'cleans messages via FK without per-message callbacks on author deletion' do
    author = users(:user_three)
    entry.entry_messages.create!(user: author, body: 'Hello')
    expect(ActionCable.server).not_to receive(:broadcast)
    author.destroy!
    expect(EntryMessage.where(user_id: author.id)).to be_empty
    expect(Entry.exists?(entry.id)).to be(true)
  end

  it 'cleans messages via FK without per-message callbacks on entry deletion' do
    entry.entry_messages.create!(user: users(:user_one), body: 'Hello')
    expect(ActionCable.server).not_to receive(:broadcast)
    entry.destroy!
    expect(EntryMessage.where(entry_id: entry.id)).to be_empty
  end

  it 'does not fail an already persisted message when broadcasting is unavailable' do
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError)
    expect { post_json path, login_user: users(:user_one), params: { body: 'Saved' } }.to change(EntryMessage, :count).by(1)
    expect(response).to have_http_status(201)
  end
end
