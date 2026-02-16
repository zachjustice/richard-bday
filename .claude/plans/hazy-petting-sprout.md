# Create Testing Rules Files

## Context

Claude agents writing tests for this project repeatedly make the same mistakes: forgetting to stub broadcasts, mixing up base classes, not knowing about custom helpers, and missing fixture isolation patterns. Two rules files scoped to their respective test directories will prevent these recurring issues.

## Files to create

### 1. `.claude/rules/ruby-testing.md`

Scoped via frontmatter to `test/**/*.rb` (excludes system tests with a second glob or note).

**Content covers:**

- **Base classes**: `ActiveSupport::TestCase` for model/service/job tests, `ActionDispatch::IntegrationTest` for controller tests (never `ActionController::TestCase`)
- **Broadcast stubbing** (required in model/service/job tests that create records with `after_commit` callbacks):
  ```ruby
  Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
  Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
  Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
  Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }
  ```
- **Fixture isolation**: Use `SecureRandom.hex(4)` suffixes when creating inline records; OR call `destroy_all` on fixture data that could collide. Never mix fixtures and inline records for the same association without cleanup.
- **Session helpers** (controller/integration tests): `resume_session_as(code, name)`, `sign_in_as_editor(editor)`, `end_session`, `sign_out_editor`
- **Test helpers**: `Helpers` class in `test/helpers/helpers.rb` provides `create_users`, `create_answers`, `create_votes`, `move_to_answering`
- **Parallel safety**: Tests run in parallel (`parallelize(workers: :number_of_processors)`). Each test must be fully isolated - no shared mutable state.
- **Result patterns**: Services return `Success`/`Failure` data objects. Assert with `assert_kind_of ServiceName::Success, result` not `result.success?`.

### 2. `.claude/rules/system-testing.md`

Scoped via frontmatter to `test/system/**/*.rb`.

**Content covers:**

- **Base class**: `ApplicationSystemTestCase` (in `test/application_system_test_case.rb`), extends `ActionDispatch::SystemTestCase`
- **Driver**: Cuprite (headless Chrome), screen size 1400x1400
- **Async helpers** (must use before interacting with broadcast-dependent UI):
  - `wait_for_turbo_cable_connection(timeout: 5)` - waits for ActionCable WebSocket
  - `wait_for_page_ready(controller: nil, timeout: 5)` - waits for Stimulus + Cable
- **Accessibility**: `assert_accessible(skip_rules: [])` runs axe-core WCAG 2.1 AA audit. Call on every new page/state.
- **Multi-user sessions**: `using_session(:player1) { ... }` for multiplayer test flows
- **Job control**: `perform_enqueued_jobs(except: [AnsweringTimesUpJob, VotingTimesUpJob])` - run jobs but exclude timer-based fallbacks that interfere with test flow
- **Capybara DSL**: `visit`, `fill_in`, `click_button`, `assert_text`, `assert_selector`, `page.execute_script`
- **No broadcast stubbing needed**: System tests run real ActionCable connections

## Verification

1. Confirm both files are created with correct frontmatter paths
2. Review content for accuracy against actual test patterns
3. No tests to run - these are documentation-only files
