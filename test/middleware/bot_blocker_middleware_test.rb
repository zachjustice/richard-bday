require "test_helper"
require "rack/mock"

class BotBlockerMiddlewareTest < ActiveSupport::TestCase
  def app
    # Inner app just echoes OK
    @app ||= BotBlockerMiddleware.new(->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ "ok" ] ] })
  end

  test "fishy path returns custom 200 body without hitting inner app" do
    env = Rack::MockRequest.env_for("/cgi-bin/exploit")

    # Avoid depending on presence of public/404-v2.html in test env
    File.stub(:read, "blocked") do
      status, _headers, body = app.call(env)

      assert_equal 200, status
      assert_equal [ "blocked" ], body.each.to_a
    end
  end

  test "firefox ai header triggers 301 redirect to https babble" do
    env = Rack::MockRequest.env_for("/anything", {
      "HTTP_X_FIREFOX_AI" => "1",
      "HTTP_HOST" => "www.example.com"
    })

    status, headers, _body = app.call(env)

    assert_equal 301, status
    assert_equal "https://www.example.com/babble", headers["Location"]
  end
end
