require "rails_helper"

RSpec.describe PushMessage do
  it "builds an entry-change notification snapshot" do
    entry = entries(:entry_one)
    message = described_class.for_entry_change(
      entry: entry,
      topic: topics(:one),
      actor: users(:user_one),
      action: :created
    )

    expect(message.title).to eq(topics(:one).title)
    expect(message.body).to include(users(:user_one).nick_name, entry.title)
    expect(message.data).to eq(
      deeplink: "https://sharablepiggy.com/topics/#{entry.topic_id}/entries/#{entry.id}"
    )
  end

  it "links a deleted entry notification to its UTC date" do
    entry = entries(:entry_one)
    message = described_class.for_entry_change(
      entry: entry,
      topic: topics(:one),
      actor: users(:user_one),
      action: :deleted
    )
    occurred_at = URI.encode_www_form(occurred_at: entry.occurred_at.utc.iso8601)

    expect(message.data).to eq(
      deeplink: "https://sharablepiggy.com/topics/#{entry.topic_id}/entries?#{occurred_at}"
    )
  end
end
