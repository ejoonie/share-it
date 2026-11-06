class ChatContentFilter
  DEFAULT_BLOCKED_PHRASES = [
    'kill yourself',
    'child porn',
    'send nudes',
    'fuck you',
    '시발',
    '씨발',
    '병신',
    '죽어버려',
    '자살해',
    '아동 포르노',
    '몰카 판매'
  ].freeze

  def self.blocked?(body)
    normalized = normalize(body)
    blocked_phrases.any? { |phrase| normalized.include?(phrase) }
  end

  def self.blocked_phrases
    configured = ENV.fetch('CHAT_BLOCKED_TERMS', '').split(',')
    (DEFAULT_BLOCKED_PHRASES + configured).map { |term| normalize(term) }.reject(&:blank?).uniq
  end

  def self.normalize(text)
    text.to_s.unicode_normalize(:nfkc).downcase.gsub(/[\p{Cf}]/, '').gsub(/\s+/, ' ').strip
  end
end
