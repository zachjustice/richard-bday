require "test_helper"

class BotBlockerMiddlewareIntegrationTest < ActionDispatch::IntegrationTest
  test "AI bot user agent is redirected to babble over https" do
    get "/some/path", headers: { "User-Agent" => "GPTBot" }

    assert_response :moved_permanently
    assert_equal "https://www.example.com/babble", response.headers["Location"]
  end

  test "Normal request succeeds" do
    get "/", headers: { "User-Agent" => "Firefox" }

    assert_response :ok
  end

  test "Unmatched request 404s" do
    get "/asdf/asdf/asdf/asdf", headers: { "User-Agent" => "Firefox" }

    assert_response :not_found
  end
end
