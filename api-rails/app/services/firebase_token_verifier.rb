require 'net/http'
require 'json'
require 'jwt'
require 'openssl'

class FirebaseTokenVerifier
  CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

  class VerificationError < StandardError; end

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

    JSON.parse(Base64.urlsafe_decode64(parts[0] + '=='))
  rescue JSON::ParserError
    raise VerificationError, 'Malformed Firebase token header'
  end

  def fetch_public_key(kid)
    raise VerificationError, 'Firebase token missing kid header' if kid.blank?

    certs = fetch_certs
    cert_pem = certs[kid]
    raise VerificationError, "No public key found for kid: #{kid}" unless cert_pem

    OpenSSL::X509::Certificate.new(cert_pem).public_key
  end

  def fetch_certs
    uri = URI(CERTS_URL)
    response = Net::HTTP.get_response(uri)
    raise VerificationError, 'Failed to fetch Firebase public keys' unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise VerificationError, 'Failed to parse Firebase public keys'
  end
end
