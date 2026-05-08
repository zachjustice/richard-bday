# Auto-load Test Helpers in Rails Console

## Context
`test/helpers/helpers.rb` defines a `Helpers` class for quick test data setup (users, answers, votes, etc.) with sane defaults. It should be available automatically when opening `rails console` so developers can quickly seed data without manual `require` calls.

## Change

**File:** `config/environments/development.rb`

Add a `console` block at the end of the `Rails.application.configure` block (before the closing `end`):

```ruby
  # Auto-load test helpers in rails console
  console do
    require Rails.root.join("test/helpers/helpers")
  end
```

This makes the `Helpers` class available immediately in `rails console`:

```ruby
h = Helpers.new        # uses Room.last!
h.create_users         # fills all player slots
h.create_answers       # all players answer
```

## Verification
- Open `rails console` and confirm `Helpers` is defined (`Helpers.new` shouldn't raise `NameError`)
- Confirm `rails server` still starts without loading the test helper (the `console` block only runs for console sessions)
