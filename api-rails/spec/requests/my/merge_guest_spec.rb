require "rails_helper"

RSpec.describe 'Retired guest merge', type: :request do
  it 'does not expose a merge endpoint or transfer guest data' do
    guest = users(:guest_user)
    owner_ids = guest.topics.pluck(:user_id)
    post_json '/api/v1/my/account/merge_guest',
      params: { guest_token: guest.token },
      headers: { 'X-Token' => users(:user_two).token }
    expect(response).to have_http_status(404)
    expect(guest.topics.reload.pluck(:user_id)).to eq(owner_ids)
    expect(User.exists?(guest.id)).to be true
  end
end
