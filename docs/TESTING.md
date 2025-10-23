# Testing Guide

## Test Types

This application has three types of tests:

### 1. Unit and Controller Tests
Located in `test/models/` and `test/controllers/`. These test individual components and controller actions.

```bash
# Run all unit and controller tests
bin/rails test test/models test/controllers
```

### 2. Integration Tests (Recommended for E2E)
Located in `test/integration/`. These test complete user flows through the request/response cycle without requiring a browser.

**Key Test:** `test/integration/game_flow_integration_test.rb` - Complete end-to-end test of the entire game flow from start to finish.

```bash
# Run integration tests
bin/rails test test/integration

# Run specific E2E test
bin/rails test test/integration/game_flow_integration_test.rb
```

**Advantages:**
- No browser required
- Fast execution
- Reliable in all environments (including WSL, Docker, CI)
- Tests full request/response cycle
- Verifies database state and redirects

### 3. System Tests (Optional - Requires Browser)
Located in `test/system/`. These test the UI using a real browser (Chrome/Chromium) via Cuprite.

**Requirements:**
- Chrome or Chromium must be installed
- Not available in WSL without additional setup

```bash
# Run system tests (will skip if Chrome not available)
bin/rails test test/system
```

#### Installing Chrome for System Tests

**On Ubuntu/Debian:**
```bash
# Install Chromium
sudo apt-get update
sudo apt-get install chromium-browser

# Or install Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f
```

**On macOS:**
```bash
# Install Chrome
brew install --cask google-chrome

# Or install Chromium
brew install chromium
```

**In WSL:**
System tests will be automatically skipped if Chrome is not available. Use integration tests instead.

## Running All Tests

```bash
# Run entire test suite
bin/rails test

# Run with verbose output
bin/rails test --verbose

# Run specific test file
bin/rails test test/integration/game_flow_integration_test.rb
```

## Test Coverage

### End-to-End Test Coverage

The `game_flow_integration_test.rb` covers the complete happy path:

1. ✅ Room creation and user registration
2. ✅ Game start with story selection
3. ✅ Answer submission (multiple players)
4. ✅ Waiting for all players
5. ✅ Voting phase
6. ✅ Results display with winner
7. ✅ Advancing to next prompt
8. ✅ Multiple rounds
9. ✅ Final results with complete story
10. ✅ Game end and reset

**40+ assertions** verify:
- User names appear correctly
- Prompts display properly
- Answers are submitted and stored
- Voting excludes own answers
- Winners are calculated correctly
- Story blanks are filled correctly
- Room state transitions properly

## Test Philosophy

Following `Claude.md` guidelines:
- ✅ Minimal tests covering critical paths
- ✅ Focus on request specs over controller specs
- ✅ System tests optional (integration tests preferred)
- ✅ Tests cover most important requirements

## CI/CD Considerations

For CI environments:
- Integration tests will always work (no browser required)
- System tests will skip gracefully if browser unavailable
- Add Chrome installation step to CI if system tests are needed

## Debugging Tests

```bash
# Run single test
bin/rails test test/integration/game_flow_integration_test.rb:26

# Run with backtrace
bin/rails test test/integration/game_flow_integration_test.rb --backtrace

# Run in verbose mode
bin/rails test --verbose
```

## Test Data

Tests use fixtures from `test/fixtures/`:
- `stories.yml` - Test story templates
- `blanks.yml` - Blank placeholders with tags
- `prompts.yml` - Questions matched to blanks
- `rooms.yml` - Test rooms
- `users.yml` - Test users

The E2E test creates fresh data to avoid fixture conflicts.

## Best Practices

1. **Prefer Integration Tests** - They're faster and more reliable
2. **Minimal Assertions** - Only verify essential information
3. **Clear Test Names** - Describe what is being tested
4. **Clean Setup** - Create fresh data in setup blocks
5. **Idempotent Tests** - Tests should be runnable in any order
