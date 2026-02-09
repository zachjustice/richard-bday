module Tokenable
  extend ActiveSupport::Concern

  class_methods do
    def digest(token)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, token)
    end

    def generate_token
      SecureRandom.urlsafe_base64(32)
    end
  end
end
