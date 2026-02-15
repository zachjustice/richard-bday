# Blanksies

## Overview
- This is a multiplayer fill-in-the-blank-style game where players fill in blanks in a story, vote on the best answers, and see a completed story at the end.
- Friends gather together in a shared space and follow the directives from the room status screen typically displayed on a TV or monitor that everyone can see.
- Over the course of the game, players answer prompts, vote on their favorite answers, and the winning responses fill in the blanks of the story.

## Tech Stack
- **Framework:** Ruby on Rails 8.0
- **Database:** SQLite3 (production-ready with solid_cache, solid_queue, solid_cable)
- **Web Server:** Puma with Thruster
- **Deployment:** Kamal with Docker containers
- **CI/CD:** GitHub Actions
- **Container Registry:** GitHub Container Registry (ghcr.io)
- Also using: Turbo, Stimulus, ActiveJob, Tailwind v4, ActionCable

## Developer Guidelines
- Before adding new components in components.css check, first check if it already exists in components.css 
- Strongly prefer using tailwind utility classes whenever possible 
- However, create component classes when:
  - The pattern is reused multiple times, OR
  - Utility-based implementation is not possible
- Create partials when any of the following is true:
  - Required for Turbo Streams
  - Component is frequently reused
  - Component is highly complex
- Use @layer base, @layer components, @layer utilities as appropriate
- Place css animations in applications.css

## Accessibility
- All new UI must meet WCAG 2.1 AA. Use `/a11y` to audit changes.
- Semantic HTML: `<nav>`, `<main>`, `<button>`, proper heading hierarchy
- Icon-only buttons/links require `aria-label`
- Modals/drawers: `role="dialog"`, `aria-modal="true"`, focus trap (reuse `concerns/focus_trap.js`), Escape to close
- Dynamic content updates need `aria-live` regions
- Animations must have `@media (prefers-reduced-motion: reduce)` coverage
- Run `rails test test/system/accessibility_test.rb` to verify

## Discord Activity / Iframe
- Discord's proxy follows HTTP redirects server-side and **strips the Authorization header** on redirect follows. This means the redirected request arrives at our app without the Bearer token, `discord_authenticated?` returns false, and Rails' default `X-Frame-Options: SAMEORIGIN` blocks the iframe.
- **Never use `redirect_to` in controller paths reachable by Discord players.** Use `turbo_nav_or_redirect_to` instead — it renders a Turbo Stream navigate action so navigation happens client-side where the Bearer token interceptor injects the auth header.
- Creator-only paths (e.g. `room_status_path`) can still use `redirect_to` since creators use a separate browser tab, not the Discord iframe.

## Testing
- Ensure tests pass after adding new features
- Add tests intentionally- tests have 2 costs: 1) maintenance and 2) running them. Ensure critical code paths are covered.