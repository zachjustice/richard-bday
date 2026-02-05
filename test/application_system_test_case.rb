require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper

  driven_by :cuprite, screen_size: [ 1400, 1400 ], options: {
    headless: true
  }

  setup do
    # Clean cable messages before each system test to prevent interference
    SolidCable::Message.delete_all if defined?(SolidCable::Message)
  end

  teardown do
    # Clean up after each test as well
    SolidCable::Message.delete_all if defined?(SolidCable::Message)
  end

  # Wait for Turbo Stream cable connection to be established
  # This prevents race conditions where broadcasts are sent before the client connects
  def wait_for_turbo_cable_connection(timeout: 5)
    assert_selector("turbo-cable-stream-source[connected]", visible: :all, wait: timeout)
  end
end
