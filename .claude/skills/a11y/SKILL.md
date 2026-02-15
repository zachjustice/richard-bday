---
name: a11y
description: Audit accessibility for views and components. Use when implementing new UI features, modifying templates, or when the user asks to check accessibility compliance.
argument-hint: [file-or-feature]
allowed-tools: Read, Grep, Glob, Bash(rails test:*)
user-invocable: true
---

# Accessibility Audit

Audit the specified files or feature for WCAG 2.1 AA compliance. If no arguments are provided, audit recently changed files (`git diff --name-only`).

## Target Files

Identify the relevant `.html.erb`, `.js`, and `.css` files from: $ARGUMENTS

If no arguments provided, find changed view/JS/CSS files:
```bash
git diff --name-only HEAD | grep -E '\.(erb|js|css)$'
```

## Checklist

For each file, check the following:

### HTML/ERB Templates
1. **Semantic HTML** — `<nav>`, `<main>`, `<button>`, `<section>` used instead of generic `<div>`s
2. **Heading hierarchy** — h1 → h2 → h3 without skipping levels
3. **Form labels** — every input has an associated `<label for="id">` or `aria-label`
4. **Icon-only buttons/links** — must have `aria-label` (not just `title`)
5. **Images** — `alt` text on `<img>`, decorative images use `alt=""` or `aria-hidden="true"`
6. **Decorative elements** — SVGs, doodles, etc. have `aria-hidden="true"`
7. **Modals/drawers** — `role="dialog"`, `aria-modal="true"`, `aria-label`, `aria-hidden` toggling
8. **Dynamic content** — `aria-live="polite"` regions for content that updates without page reload
9. **Links vs buttons** — `<a>` for navigation, `<button>` for actions

### JavaScript/Stimulus Controllers
10. **Focus trap** — modals/drawers use `concerns/focus_trap.js` for Tab key trapping
11. **Escape key** — modals/drawers close on Escape
12. **Focus restoration** — focus returns to trigger element when modal closes
13. **Keyboard navigation** — interactive components respond to Arrow keys, Enter, Space as appropriate
14. **Screen reader announcements** — use `aria-live` regions for state changes

### CSS/Tailwind
15. **Reduced motion** — all animations listed in `@media (prefers-reduced-motion: reduce)` in application.css
16. **Focus styles** — interactive elements have visible `focus-visible` styles
17. **Hidden content** — use `sr-only` class (not `display: none`) for screen-reader-only text

## Existing Patterns to Reference
- Focus trap: `app/javascript/concerns/focus_trap.js`
- Modal pattern: `app/javascript/controllers/leave_game_modal_controller.js`
- ARIA live announcer: `app/javascript/controllers/auto_submitter_controller.js` (lines 20-27)
- Ranked voting keyboard support: `app/javascript/controllers/ranked_voting_controller.js`
- Reduced motion: `app/assets/tailwind/application.css` (lines 272-300)

## After Audit

1. Report findings with specific file paths and line numbers
2. Prioritize by WCAG level (A > AA > AAA)
3. Run automated checks:
   ```bash
   rails test test/system/accessibility_test.rb test/system/accessibility_behaviors_test.rb
   ```
4. Suggest fixes referencing existing patterns in the codebase

## About `assert_accessible` (test helper)

The `assert_accessible` helper in `test/application_system_test_case.rb` runs axe-core WCAG 2.1 AA checks. Key things to know:

- **Custom JS injection, not axe-core-capybara** — Cuprite (our headless Chrome driver) doesn't support Selenium's `execute_async_script`, so we inject axe-core JS directly and poll for results.
- **Animation neutralization** — The helper automatically finishes/cancels CSS animations, forces opacity to 1, and disables future animations before running axe. Without this, mid-animation partial opacity causes axe to compute wrong blended colors (false contrast failures).
- **Decorative overlay removal** — Fixed-position `aria-hidden="true"` elements (doodle SVGs) and all `background-image` values are stripped to prevent axe's color compositing from being confused.
- **Semi-transparent background handling** — `rgba` backgrounds are made opaque and `backdrop-filter` is removed before the scan.
- **Scoped to `#main-content`** — axe runs against `#main-content` (not `document`) when available, avoiding false positives from full-page background compositing in headless Chrome.
- **`skip_rules:` parameter** — Pass an array of axe rule IDs to suppress (e.g., `assert_accessible(skip_rules: ["color-contrast"])`) for rare edge cases. Prefer fixing the issue over skipping.
