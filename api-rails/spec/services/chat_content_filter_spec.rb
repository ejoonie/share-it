require 'rails_helper'

RSpec.describe ChatContentFilter do
  it 'normalizes full-width, casing, whitespace and invisible characters' do
    expect(described_class.blocked?("ＫＩＬＬ\u200B  YOURSELF")).to be(true)
    expect(described_class.blocked?("씨\u200B발")).to be(true)
    expect(described_class.blocked?('오늘 식비 나눠줘')).to be(false)
  end

  it 'normalizes configured phrases using the same rules' do
    allow(ENV).to receive(:fetch).with('CHAT_BLOCKED_TERMS', '').and_return(' CUSTOM   PHRASE ,')
    expect(described_class.blocked?('custom phrase')).to be(true)
    expect(described_class.blocked?('ordinary message')).to be(false)
  end
end
