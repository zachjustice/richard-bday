# CLAUDE.md

## Purpose
This document outlines the expectations, coding standards, and general conventions for contributing to this Ruby on Rails project. It serves as a guide for LLM agents to produce clean, maintainable, and idiomatic Rails code.

---

## General Principles
- Use **Rails 8** defaults unless otherwise specified.
- Follow **Convention Over Configuration** wherever possible.
- Keep controllers slim, models focused, and favor service objects or POROs for business logic.
- Use Hotwire (Turbo + Stimulus) as the primary frontend stack.
- Prioritize readability and simplicity over "clever" code.

---

## Code Style
- Follow [Ruby Style Guide](https://rubystyle.guide/).
- Use `rubocop` for automated linting.

**Naming Conventions:**
- Use descriptive names (avoid abbreviations).
- Scopes, services, and helpers should be named by function, not technology.

**SQL Queries:**
- Prefer ActiveRecord querying methods.
- If using `.pluck`, `.select`, or `.find_by_sql`, document why.

---

## Folder Structure and Patterns
- Place service objects in `/app/services/`.
- Use `/app/queries/` for complex database query objects.
- Place form objects in `/app/forms/` when needed.
- Use `/app/components/` for ViewComponent classes if used.

---

## Controllers
- Keep controllers RESTful.
- Do not embed business logic in controllers.
- Respond with JSON or Turbo Streams depending on frontend needs.

---

## Views and Frontend
- Use Turbo Frames and Turbo Streams where possible.
- Avoid JavaScript unless required. Use Stimulus controllers instead.
- Keep ERB templates clean — minimize logic in views.

---

## Testing
- Use `minitest` for tests unless otherwise specified.
- Focus on:
  - Model specs
  - Request specs (not controller specs)
  - System specs (if testing UI interactions)
- Write the minimum amount of tests to cover the most critical requirements and code paths.

---

## ActiveRecord Best Practices
- Default scopes are discouraged.
- Use `readonly` where applicable for reporting queries.
- Use `enum` cautiously — prefer plain constants if behavior is complex.

---

## Background Jobs
- Use `SolidQueue` for background jobs.
- Place jobs in `/app/jobs/`.
- Keep jobs idempotent.

---

## Security
- Never trust params directly — use strong parameters.
- Avoid inline SQL to prevent SQL injection.
- Sanitize user input in views.
- Regularly check for gem vulnerabilities (`bundle audit`).

---

## Dependencies
- Avoid adding gems unless necessary.
- If adding a gem, document why in the Pull Request.
- Favor gems that follow Rails 7+ conventions and are actively maintained.

---

## Git and Code Review
- Use feature branches.
- Write clear, concise commit messages.
- Squash commits before merging unless history is meaningful.
- All PRs must:
  - Be peer-reviewed.
  - Pass all CI checks.
  - Include tests for new/modified behavior.

---

## Communication Style
- Write comments and documentation in plain, professional language.
- Explain *why* something exists, not *what* it does (code should explain itself).

---

## Tools & CI
- Ensure:
  - `rubocop` or `standardrb` passes.
  - RSpec suite runs green.
  - Any linting/CI tools configured per project pass before merge.