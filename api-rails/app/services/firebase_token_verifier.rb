require 'net/http'
require 'json'
require 'jwt'
require 'openssl'

class FirebaseTokenVerifier
  CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

  class VerificationError < StandardError; end

  # Class-level certificate cache shared across instances
  @certs_cache = nil
  @certs_expires_at = nil
  @certs_mutex = Mutex.new

  class << self
    attr_accessor :certs_cache, :certs_expires_at, :certs_mutex
  end

  def initialize(firebase_token)
    @firebase_token = firebase_token
  end

  # Returns the Firebase UID on success, raises VerificationError on failure.
  def verify!
    project_id = ENV.fetch('FIREBASE_PROJECT_ID') { raise VerificationError, 'FIREBASE_PROJECT_ID not configured' }

    header = decode_header
    public_key = fetch_public_key(header['kid'])

    payload, = JWT.decode(
      @firebase_token,
      public_key,
      true,
      algorithms: ['RS256'],
      iss: "https://securetoken.google.com/#{project_id}",
      aud: project_id,
      verify_iss: true,
      verify_aud: true,
      verify_expiration: true
    )

    uid = payload['sub'] || payload['user_id']
    raise VerificationError, 'Firebase token missing uid' if uid.blank?

    uid
  rescue JWT::DecodeError => e
    raise VerificationError, "Invalid Firebase token: #{e.message}"
  end

  private

  def decode_header
    parts = @firebase_token.split('.')
    raise VerificationError, 'Malformed Firebase token' unless parts.length == 3

    # Add correct Base64 padding (0, 1, or 2 '=' chars as needed)
    b64 = parts[0]
    padded = b64 + '=' * ((4 - b64.length % 4) % 4)
    JSON.parse(Base64.urlsafe_decode64(padded))
  rescue JSON::ParserError
    raise VerificationError, 'Malformed Firebase token header'
  end

  def fetch_public_key(kid)
    raise VerificationError, 'Firebase token missing kid header' if kid.blank?

    certs = cached_certs
    cert_pem = certs[kid]
    raise VerificationError, "No public key found for kid: #{kid}" unless cert_pem

    OpenSSL::X509::Certificate.new(cert_pem).public_key
  end

  def cached_certs
    self.class.certs_mutex.synchronize do
      return self.class.certs_cache if self.class.certs_cache && Time.now < self.class.certs_expires_at

      uri = URI(CERTS_URL)
      response = Net::HTTP.get_response(uri)
      raise VerificationError, 'Failed to fetch Firebase public keys' unless response.is_a?(Net::HTTPSuccess)

      certs = JSON.parse(response.body)
      max_age = parse_max_age(response['cache-control']) || 3600
      self.class.certs_cache = certs
      self.class.certs_expires_at = Time.now + max_age
      certs
    end
  rescue JSON::ParserError
    raise VerificationError, 'Failed to parse Firebase public keys'
  end

  def parse_max_age(cache_control_header)
    return nil if cache_control_header.blank?

    match = cache_control_header.match(/max-age=(\d+)/)
    match ? match[1].to_i : nil
  end
end
