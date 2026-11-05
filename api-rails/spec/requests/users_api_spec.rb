require "rails_helper"

RSpec.describe "Retired guest login", type: :request do
  it "rejects guest creation without creating an account" do
    expect {
      post_json "/api/v1/guest_login", params: { guest_token: "legacy-client" }
    }.not_to change(User, :count)
    expect(response).to have_http_status(410)
  end

  it "rejects legacy guest tokens for private data without deleting the account" do
    guest = users(:guest_user)
    get "/api/v1/my/bootstrap", headers: { "X-Token" => guest.token }
    expect(response).to have_http_status(401)
    expect(User.exists?(guest.id)).to be true
  end
end
