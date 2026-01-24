module Tokenable
  extend ActiveSupport::Concern

  class_methods do
    def digest(token)
      Digest::SHA256.hexdigest(token)
    end

    def generate_token
      SecureRandom.urlsafe_base64(32)
    end
  end
end
