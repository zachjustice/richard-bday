require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper

  driven_by :cuprite, screen_size: [ 1400, 1400 ], options: {
    headless: true,
    browser_options: ENV["CI"].present? ? {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil
    } : {}
  }

  # Wait for Turbo Stream cable connection to be established
  # This prevents race conditions where broadcasts are sent before the client connects
  def wait_for_turbo_cable_connection(timeout: 5)
    assert_selector("turbo-cable-stream-source[connected]", visible: :all, wait: timeout)
  end

  # Wait for page to be fully interactive (Stimulus connected + Turbo Cable ready)
  # Use this before executing JavaScript that depends on Stimulus controllers
  def wait_for_page_ready(controller: nil, timeout: 5)
    # If a specific Stimulus controller is required, wait for it
    if controller
      assert_selector "[data-controller='#{controller}']", wait: timeout
    end

    # Wait for Turbo cable connection if present on the page
    if page.has_selector?("turbo-cable-stream-source", visible: :all, wait: 0.5)
      wait_for_turbo_cable_connection(timeout: timeout)
    end
  end
end
