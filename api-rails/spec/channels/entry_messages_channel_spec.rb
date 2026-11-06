require 'rails_helper'

RSpec.describe EntryMessagesChannel, type: :channel do
  let(:entry) { entries(:entry_one) }
  let(:user) { users(:user_one) }

  before { stub_connection current_user: user, chat_entry_id: entry.id }

  it 'subscribes an authenticated follower to only the ticket entry' do
    subscribe(entry_id: entry.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("entry_chat_#{entry.id}")
  end

  it 'checks current access with one database query per delivery' do
    subscribe(entry_id: entry.id)
    queries = []
    callback = ->(*args) { payload = args.last; queries << payload[:sql] unless payload[:name] == 'SCHEMA' }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      expect(subscription.send(:accessible?)).to be(true)
    end
    expect(queries.grep(/SELECT/).size).to eq(1)
  end

  it 'rejects a different entry than the signed ticket' do
    subscribe(entry_id: entries(:entry_two).id)
    expect(subscription).to be_rejected
  end

  it 'rejects a non-follower' do
    stub_connection current_user: users(:user_two), chat_entry_id: entry.id
    subscribe(entry_id: entry.id)
    expect(subscription).to be_rejected
  end

  it 'does not deliver invalidations for a blocked message author' do
    callback = nil
    subscribe(entry_id: entry.id)
    allow(subscription).to receive(:stream_from) { |*_args, &block| callback = block }
    subscription.subscribed
    blocked = users(:user_three)
    ChatBlock.create!(blocker: user, blocked: blocked)

    callback.call('type' => 'changed', 'message_id' => 10, 'author_id' => blocked.id)
    expect(transmissions).to be_empty
    callback.call('type' => 'changed', 'message_id' => 11, 'author_id' => user.id)
    expect(transmissions.last).to include('message_id' => 11)
  end

  [:banned, :unfollowed, :deleted_entry, :deleted_topic, :rotated_token].each do |state|
    it "stops delivery after #{state}" do
      callback = nil
      subscribe(entry_id: entry.id)
      allow(subscription).to receive(:stream_from) { |*_args, &block| callback = block }
      subscription.subscribed
      follow = user.topic_follows.find_by!(topic_id: entry.topic_id)
      case state
      when :banned then follow.update!(permissions: ['banned'])
      when :unfollowed then follow.destroy!
      when :deleted_entry then entry.soft_delete!
      when :deleted_topic then entry.topic.soft_delete!
      when :rotated_token then User.where(id: user.id).update_all(token: 'rotated')
      end
      callback.call('type' => 'changed')
      expect(transmissions.last).to eq('type' => 'access_revoked')
      expect(subscription).not_to have_streams
    end
  end
end
