require 'jwt'
require 'securerandom'
require "base64"

module Nuabase
  class NuaTokenGenerator
    class InvalidSecretKeyError < StandardError; end

    SIGNING_KEY_PREFIX = "pk_".freeze
    ALGORITHM = 'HS256'.freeze
    EXPIRY_SECONDS = 180

    def initialize(signing_key_secret:, user_id:, expiry_seconds: EXPIRY_SECONDS)
      @user_id = user_id
      @expiry_seconds = expiry_seconds
      parse_signing_key(signing_key_secret)
    end

    def generate
      current_time = Time.now.to_i

      payload = {
        iss: @client_id,
        sub: @user_id,
        kid: @key_id,
        jti: SecureRandom.uuid,
        exp: current_time + @expiry_seconds,
        iat: current_time,
        aud: "https://api.nuabase.com"
      }

      token = JWT.encode(payload, @secret_b64, ALGORITHM)

      {
        access_token: token,
        expires_in: @expiry_seconds,
        expires_at: payload[:exp]
      }
    end

    private

    def parse_signing_key(signing_key_secret)
      raise InvalidSecretKeyError, "invalid Nuabase token secret" unless signing_key_secret.start_with?(SIGNING_KEY_PREFIX)
      body = signing_key_secret[SIGNING_KEY_PREFIX.length..] # strip "pk_"
      parts = body.split(".", 3)
      raise InvalidSecretKeyError, "invalid API key format" unless parts.size == 3
      client_id_b64, key_id_b64, @secret_b64 = parts
      @client_id = Base64.urlsafe_decode64(client_id_b64)
      @key_id = Base64.urlsafe_decode64(key_id_b64)
    end
  end
end
