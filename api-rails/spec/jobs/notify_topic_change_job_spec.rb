require "rails_helper"

RSpec.describe NotifyTopicChangeJob, type: :job do
  let(:topic) { topics(:one) }
  let(:entry) { entries(:entry_one) }
  let(:actor) { users(:user_one) }
  let!(:device_token) { DeviceToken.create!(user: users(:guest_user), token: "device-token-1", platform: "ios") }

  def perform
    described_class.new.perform(
      device_token_ids: [device_token.id],
      topic_id: topic.id,
      entry_id: entry.id,
      actor_id: actor.id,
      occurred_at: entry.occurred_at&.iso8601,
      action: "created"
    )
  end

  context "when Firebase is not configured" do
    it "does nothing" do
      allow(FcmClient).to receive(:configured?).and_return(false)
      expect(FcmClient).not_to receive(:send_message)

      perform
    end
  end

  context "when Firebase is configured" do
    before { allow(FcmClient).to receive(:configured?).and_return(true) }

    it "sends a message built from the topic/entry/actor to each device token" do
      expect(FcmClient).to receive(:send_message).with(
        token: device_token.token,
        title: topic.title,
        body: a_string_including(actor.nick_name).and(a_string_including(entry.title)),
        data: hash_including(
          type: "entry_change",
          topic_id: topic.id,
          entry_id: entry.id,
          action: "created"
        )
      ).and_return(instance_double(Net::HTTPOK).tap { |r| allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) })

      perform
    end

    it "deletes the device token when FCM reports it as unregistered" do
      error_response = instance_double(
        Net::HTTPNotFound,
        body: { error: { details: [{ errorCode: "UNREGISTERED" }] } }.to_json
      )
      allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(FcmClient).to receive(:send_message).and_return(error_response)

      expect { perform }.to change(DeviceToken, :count).by(-1)
      expect(DeviceToken.exists?(device_token.id)).to be false
    end

    it "keeps the device token and just logs on other errors" do
      error_response = instance_double(
        Net::HTTPInternalServerError,
        code: "500",
        body: { error: { status: "INTERNAL" } }.to_json
      )
      allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(FcmClient).to receive(:send_message).and_return(error_response)

      expect { perform }.not_to change(DeviceToken, :count)
    end

    it "does nothing when there are no device tokens" do
      expect(FcmClient).not_to receive(:send_message)

      described_class.new.perform(
        device_token_ids: [],
        topic_id: topic.id,
        entry_id: entry.id,
        actor_id: actor.id,
        occurred_at: nil,
        action: "created"
      )
    end
  end
end
