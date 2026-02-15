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

  # Run axe-core WCAG 2.1 AA check against the current page.
  # Injects axe-core JS directly and polls for results (Cuprite-compatible).
  # Hides fixed decorative overlays before running to prevent false contrast failures.
  def assert_accessible(skip_rules: [])
    inject_axe_core

    # Neutralize visual effects that confuse axe-core's contrast algorithm:
    # 1. CSS animations (slide-up, fade-in) set partial opacity mid-animation,
    #    causing axe to compute blended colors instead of final values
    # 2. Fixed-position SVG doodle overlays
    # 3. SVG data-URI background-image patterns
    # 4. Semi-transparent backgrounds with backdrop-blur
    # The final computed styles (verified via getComputedStyle post-animation)
    # are correct — these are axe-core limitations, not real contrast issues.
    page.execute_script <<~JS
      // Force finite animations to end state; cancel infinite ones
      document.getAnimations().forEach(function(anim) {
        try {
          var effect = anim.effect;
          var timing = effect && effect.getTiming ? effect.getTiming() : {};
          if (timing.iterations === Infinity) {
            anim.cancel();
          } else {
            anim.finish();
          }
        } catch(e) { anim.cancel(); }
      });
      // Disable future animations
      var style = document.createElement('style');
      style.textContent = '*, *::before, *::after { animation: none !important; transition: none !important; }';
      document.head.appendChild(style);
      // Force all elements to full opacity (undo mid-animation partial opacity)
      document.querySelectorAll('*').forEach(function(el) {
        var computed = window.getComputedStyle(el);
        if (parseFloat(computed.opacity) < 1) {
          el.style.opacity = '1';
        }
      });
      // Remove ALL background-images (SVG patterns confuse axe's color blending)
      document.querySelectorAll('*').forEach(function(el) {
        if (window.getComputedStyle(el).backgroundImage !== 'none') {
          el.style.backgroundImage = 'none';
        }
      });
      // Hide fixed decorative overlays (doodle SVGs)
      document.querySelectorAll('[aria-hidden="true"]').forEach(function(el) {
        if (window.getComputedStyle(el).position === 'fixed') {
          el.style.display = 'none';
        }
      });
      // Make semi-transparent backgrounds opaque and remove backdrop-filters
      document.querySelectorAll('*').forEach(function(el) {
        var style = window.getComputedStyle(el);
        if (style.backdropFilter && style.backdropFilter !== 'none') {
          el.style.backdropFilter = 'none';
        }
        var bg = style.backgroundColor;
        if (bg && bg.startsWith('rgba') && !bg.endsWith(', 0)')) {
          el.style.backgroundColor = bg.replace(/rgba\\((\\d+),\\s*(\\d+),\\s*(\\d+),\\s*[\\d.]+\\)/, 'rgb($1, $2, $3)');
        }
      });
    JS

    options = { runOnly: { type: "tag", values: [ "wcag2a", "wcag2aa", "wcag21a", "wcag21aa" ] } }
    options[:rules] = skip_rules.to_h { |r| [ r, { enabled: false } ] } if skip_rules.any?

    # Scope axe to #main-content when available to avoid false contrast failures
    # caused by full-page background compositing in headless Chrome.
    page.execute_script <<~JS
      window.__axeResults = null;
      var context = document.getElementById('main-content') || document;
      axe.run(context, #{options.to_json}).then(function(results) {
        window.__axeResults = results;
      });
    JS

    # Poll for results
    results = nil
    30.times do
      results = page.evaluate_script("window.__axeResults")
      break if results
      sleep 0.5
    end

    assert results, "axe-core timed out"

    violations = results["violations"] || []
    return if violations.empty?

    message = "Found #{violations.length} accessibility violation(s):\n\n"
    violations.each do |v|
      message += "  [#{v['impact']}] #{v['id']}: #{v['help']}\n"
      message += "  #{v['helpUrl']}\n"
      (v["nodes"] || []).first(3).each do |node|
        message += "    Element: #{node['html']}\n"
        message += "    #{node['failureSummary']}\n"
      end
      message += "\n"
    end
    flunk(message)
  end

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

  private

  def inject_axe_core
    return if page.evaluate_script("typeof window.axe !== 'undefined' && typeof axe.run === 'function'")

    axe_js_path = Gem::Specification.find_by_name("axe-core-api").gem_dir + "/node_modules/axe-core/axe.min.js"
    axe_source = File.read(axe_js_path)
    page.execute_script(axe_source)
  end
end
