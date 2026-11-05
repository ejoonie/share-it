require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  def ticket(expires_in: 1.minute)
    user = users(:user_one)
    Rails.application.message_verifier(:chat_connection).generate(
      { user_id: user.id, entry_id: entries(:entry_one).id,
        token_digest: Digest::SHA256.hexdigest(user.token) },
      expires_in: expires_in, purpose: :chat_connection
    )
  end

  it 'authenticates a short-lived signed ticket' do
    connect '/cable', params: { ticket: ticket }
    expect(connection.current_user).to eq(users(:user_one))
    expect(connection.chat_entry_id).to eq(entries(:entry_one).id)
  end

  it 'rejects missing, tampered and expired tickets' do
    [nil, 'tampered', ticket(expires_in: -1.second)].each do |value|
      expect { connect '/cable', params: { ticket: value } }.to have_rejected_connection
    end
  end

  it 'rejects tickets after the user token changes' do
    value = ticket
    users(:user_one).update!(token: 'rotated')
    expect { connect '/cable', params: { ticket: value } }.to have_rejected_connection
  end
end
