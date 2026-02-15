# Accessibility Audit: Bug Fixes, Tests, Skill & Guidelines

## Context

An accessibility audit found the app has strong fundamentals (skip links, ARIA on ranked voting, focus traps, `prefers-reduced-motion`) but identified concrete bugs and zero automated a11y testing. This plan fixes bugs, adds axe-core tests, creates a reusable `/a11y` skill, and updates project guidelines to bake accessibility into the workflow.

---

## Part 1: Bug Fixes

### 1. Generic page title (WCAG 2.4.2 — Level A)
**File:** [application.html.erb:4](app/views/layouts/application.html.erb#L4)

Change fallback from `"Blank"` to `"Blanksies"`.

### 2. Discord navbar missing `<nav>` landmark (WCAG 1.3.1 — Level A)
**File:** [_discord_navbar.html.erb:10](app/views/shared/_discord_navbar.html.erb#L10)

Change `<div class="discord-navbar"` → `<nav class="discord-navbar"` with `aria-label="Game navigation"`. Update closing tag.

### 3. Phase progress pills missing accessible labels (WCAG 1.1.1 — Level A)
**File:** [_discord_navbar.html.erb:30-57](app/views/shared/_discord_navbar.html.erb#L30-L57)

Add `aria-label` to each phase pill (e.g. `"Answering: current phase"`, `"Voting: completed"`). Same for the "Final" pill.

### 4. Mobile nav drawer — no focus trap, no dialog role, no Escape key (WCAG 2.4.3 — Level AA)
**Files:**
- [_editor_navbar.html.erb:47](app/views/shared/_editor_navbar.html.erb#L47) — add `role="dialog"`, `aria-modal="true"`, `aria-label="Navigation menu"`, `aria-hidden="true"`
- [mobile_nav_controller.js](app/javascript/controllers/mobile_nav_controller.js) — rewrite following [leave_game_modal_controller.js](app/javascript/controllers/leave_game_modal_controller.js) pattern: import [FocusTrap](app/javascript/concerns/focus_trap.js), add `open()`/`close()` with `aria-hidden` toggling, Escape key, focus restoration

### 5. Account icon link missing `aria-label` (WCAG 1.1.1 — Level A)
**File:** [_editor_navbar.html.erb:24-26](app/views/shared/_editor_navbar.html.erb#L24-L26)

Add `"aria-label": "Account settings"` to the `link_to`.

### Not fixing
- **Flash-red animation** — 1 flash/sec, opacity only, below WCAG threshold, covered by `prefers-reduced-motion`
- **Auto-submit countdown** — already has `aria-live="polite"` announcer in [auto_submitter_controller.js:20-27](app/javascript/controllers/auto_submitter_controller.js#L20-L27)

---

## Part 2: Accessibility Tests

### 1. Add `axe-core-capybara` gem
**File:** [Gemfile](Gemfile) — add to `:test` group, run `bundle install`

### 2. Add `assert_accessible` helper
**File:** [application_system_test_case.rb](test/application_system_test_case.rb)

```ruby
require "axe/matchers/be_axe_clean"

def assert_accessible(target = page, skip_rules: [])
  matcher = Axe::Matchers::BeAxeClean.new.according_to(:wcag21aa)
  skip_rules.each { |rule| matcher = matcher.skipping(rule) }
  result = matcher.audit(target)
  assert result.passed?, result.failure_message
end
```

### 3. Axe page-level tests
**New file:** `test/system/accessibility_test.rb`

Run axe-core on pages reachable without complex game-state setup:
- Login/join page (`new_session_path`)
- Room creation page (`create_room_path`)
- Editor stories page (sign in as editor, `stories_path`)

### 4. Targeted behavior tests
**New file:** `test/system/accessibility_behaviors_test.rb`

- **Skip link** — verify element exists, focus, click, assert focus moves to `#main-content`
- **Mobile nav focus trap** — resize to mobile, sign in as editor, open drawer, verify `role="dialog"`, press Escape, verify closed
- **Mobile nav backdrop close** — click backdrop, verify closes

---

## Part 3: `/a11y` Skill

**New file:** `.claude/skills/a11y/SKILL.md`

```yaml
---
name: a11y
description: Audit accessibility for views/components. Use when implementing new UI, modifying templates, or checking accessibility.
argument-hint: [file-or-feature]
allowed-tools: Read, Grep, Glob, Bash(rails test:*)
---
```

The skill prompt instructs Claude to:
1. Identify relevant `.html.erb`, `.js`, `.css` files from `$ARGUMENTS` or recent git changes
2. Audit against checklist:
   - Semantic HTML (`<nav>`, `<main>`, `<button>` vs `<a>`, heading hierarchy)
   - Form labels associated via `for`/`id`
   - Icon-only buttons/links have `aria-label`
   - Modals/drawers have `role="dialog"`, `aria-modal`, focus trap, Escape key
   - Dynamic content uses `aria-live` regions
   - Animations have `prefers-reduced-motion` coverage
   - Images have `alt` text, decorative elements have `aria-hidden="true"`
   - Keyboard accessibility for interactive components
3. Run `rails test test/system/accessibility_test.rb` if available
4. Report findings with file paths and line numbers

---

## Part 4: CLAUDE.md & Rules Updates

### Add to CLAUDE.md
**File:** [CLAUDE.md](.claude/CLAUDE.md) — new **Accessibility** section after "Developer Guidelines":

```markdown
## Accessibility
- All new UI must meet WCAG 2.1 AA. Use `/a11y` to audit changes.
- Semantic HTML: `<nav>`, `<main>`, `<button>`, proper heading hierarchy
- Icon-only buttons/links require `aria-label`
- Modals/drawers: `role="dialog"`, `aria-modal="true"`, focus trap (reuse `concerns/focus_trap.js`), Escape to close
- Dynamic content updates need `aria-live` regions
- Animations must have `@media (prefers-reduced-motion: reduce)` coverage
- Run `rails test test/system/accessibility_test.rb` to verify
```

### Add to frontend-development.md
**File:** [frontend-development.md](.claude/rules/frontend-development.md) — new **Accessibility** subsection under "Design Guide":

```markdown
### Accessibility
- Semantic HTML (`<nav>`, `<button>`, `<main>`) over generic `<div>`s
- Icon-only interactive elements need `aria-label` (not just `title`)
- Modals/drawers: `role="dialog"`, `aria-modal="true"`, focus trap via `concerns/focus_trap.js`, Escape key
- Form inputs must have associated `<label for="id">`
- Decorative elements: `aria-hidden="true"`
- Animations must be disabled in `prefers-reduced-motion` block in application.css
```

---

## Verification

1. `bundle install` — axe-core-capybara installs
2. `rails test test/system/accessibility_test.rb` — axe checks pass
3. `rails test test/system/accessibility_behaviors_test.rb` — behavior tests pass
4. `rails test` — full suite passes
5. Manual: open mobile nav on editor pages, verify focus trap and Escape
6. `/a11y app/views/shared/_editor_navbar.html.erb` — skill runs and reports clean
