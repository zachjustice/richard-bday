class ValidateAuthHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    @req = ActionDispatch::Request.new(env)
    authorized?(env) ? response_normal: response_unauthorized
  end

  private

  def authorized?(env)
    auth = @req.authorization
    return false if auth.nil?

    maybe_user_id = Auth.decrypt(auth.split.last)
    return false if maybe_user_id.nil?

    maybe_user = User.find(maybe_user_id)
    return false if maybe_user.nil?

    env["current_user"] = maybe_user
    true
  end

  def response_normal
    @app.call(@req.env)
  end

  def response_unauthorized
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[:unauthorized]

    [ status_code, {}, [] ]
  end
end
