require "rails_helper"

RSpec.describe FcmClient do
  subject(:client) { described_class.new }

  describe "response classification" do
    def classify(response)
      client.send(:classify_response, response)
    end

    it "classifies successful responses" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      expect(classify(response)).to be_a(FcmClient::Success)
    end

    it "classifies UNREGISTERED as an invalid token" do
      response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
      allow(response).to receive(:body).and_return(
        { error: { details: [{ errorCode: "UNREGISTERED" }] } }.to_json
      )
      expect(classify(response)).to be_a(FcmClient::InvalidToken)
    end

    it "does not classify INVALID_ARGUMENT as an invalid token" do
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      allow(response).to receive(:body).and_return(
        { error: { details: [{ errorCode: "INVALID_ARGUMENT" }] } }.to_json
      )
      expect(classify(response)).to be_a(FcmClient::PermanentError)
    end

    it "classifies throttling and server failures as retryable" do
      [429, 500, 502, 503, 504].each do |status|
        response = instance_double(Net::HTTPResponse, code: status.to_s, body: "{}")
        allow(response).to receive(:[]).with("Retry-After").and_return(nil)
        expect(classify(response)).to be_a(FcmClient::RetryableError)
      end
    end

    it "uses Retry-After and defaults throttling retries to 60 seconds" do
      with_header = instance_double(Net::HTTPResponse, code: "429", body: "{}")
      allow(with_header).to receive(:[]).with("Retry-After").and_return("120")
      without_header = instance_double(Net::HTTPResponse, code: "429", body: "{}")
      allow(without_header).to receive(:[]).with("Retry-After").and_return(nil)

      expect(classify(with_header).retry_after).to eq(120)
      expect(classify(without_header).retry_after).to eq(60)
    end

    it "falls back safely when Retry-After is malformed" do
      response = instance_double(Net::HTTPResponse, code: "429", body: "{}")
      allow(response).to receive(:[]).with("Retry-After").and_return("not-a-date")

      expect(classify(response).retry_after).to eq(60)
    end
  end
end
