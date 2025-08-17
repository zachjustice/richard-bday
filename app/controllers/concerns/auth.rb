class Auth extend ActiveSupport::Concern
  def self.encrypt(text)
    text = text.to_s unless text.is_a?(String)

    len   = ActiveSupport::MessageEncryptor.key_len
    salt  = SecureRandom.hex(len)
    key   = ActiveSupport::KeyGenerator.new(Rails.application.credentials.secret_key_base).generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    encrypted_data = crypt.encrypt_and_sign(text)
    "#{salt}$$#{encrypted_data}"
  end

  def self.decrypt(text)
    salt, data = text.split("$$")
    return nil if salt.nil? || data.nil?

    len   = ActiveSupport::MessageEncryptor.key_len
    key   = ActiveSupport::KeyGenerator.new(Rails.application.credentials.secret_key_base).generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new key
    crypt.decrypt_and_verify(data)
  end
end
