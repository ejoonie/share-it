require "rails_helper"

RSpec.describe SendPushJob, type: :job do
  let!(:device_token) { DeviceToken.create!(user: users(:guest_user), token: "device-token-1", platform: "ios") }
  let(:arguments) do
    {
      device_token_id: device_token.id,
      title: "Piggy",
      body: "Alex added $10.00 for Lunch",
      data: { type: "entry_change", entry_id: 1 }
    }
  end

  context "when Firebase is not configured" do
    it "does not send" do
      allow(FcmClient).to receive(:configured?).and_return(false)
      expect(FcmClient).not_to receive(:send_message)

      described_class.new.perform(**arguments)
    end
  end

  context "when Firebase is configured" do
    before { allow(FcmClient).to receive(:configured?).and_return(true) }

    it "sends the supplied message to one token" do
      expect(FcmClient).to receive(:send_message).with(
        token: device_token.token,
        title: arguments[:title],
        body: arguments[:body],
        data: arguments[:data]
      ).and_return(FcmClient::Success.new)

      described_class.new.perform(**arguments)
    end

    it "deletes a token reported as unregistered" do
      allow(FcmClient).to receive(:send_message)
        .and_return(FcmClient::InvalidToken.new(error_codes: ["UNREGISTERED"]))

      expect { described_class.new.perform(**arguments) }
        .to change(DeviceToken, :count).by(-1)
    end

    it "raises for retryable failures" do
      allow(FcmClient).to receive(:send_message)
        .and_return(FcmClient::RetryableError.new(error: Net::ReadTimeout.new))

      expect { described_class.new.perform(**arguments) }
        .to raise_error(SendPushJob::PushDeliveryError)
    end

    it "keeps the token for permanent failures" do
      response = instance_double(Net::HTTPBadRequest, code: "400", body: "bad payload")
      allow(FcmClient).to receive(:send_message)
        .and_return(FcmClient::PermanentError.new(response: response))

      expect { described_class.new.perform(**arguments) }
        .not_to change(DeviceToken, :count)
    end

    it "does nothing when the token was removed before execution" do
      device_token.destroy!
      expect(FcmClient).not_to receive(:send_message)

      described_class.new.perform(**arguments)
    end
  end
end
