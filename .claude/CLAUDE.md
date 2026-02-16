# Blanksies

## Overview
- This is a multiplayer fill-in-the-blank-style game where players fill in blanks in a story, vote on the best answers, and see a completed story at the end.
- Friends gather together in a shared space and follow the directives from the room status screen typically displayed on a TV or monitor that everyone can see.
- Over the course of the game, players answer prompts, vote on their favorite answers, and the winning responses fill in the blanks of the story.

## Game Flow

### Phases
`WaitingRoom` → `StorySelection` → [`Answering` → `Voting` → `Results`] (loop per prompt) → `FinalResults` → `Credits`

- Phase constants defined in `app/controllers/concerns/RoomStatus.rb`
- Transitions managed by `GamePhasesService` and `RoomsController`
- Phases advance via creator action, player completion, or timeout (`time_to_answer_seconds`, `time_to_vote_seconds`)

### Voting
Two independent voting systems run during each `Voting` phase:

- **Player votes** (`vote_type: "player"`) — determine the winner
  - `vote_once`: 1 vote = 1 point
  - `ranked_top_3`: rank 3 answers → 30/20/10 points
  - Voting style set per room (`Room::VOTING_STYLES`)
- **Audience votes** (`vote_type: "audience"`) — cosmetic "audience favorite"
  - Distribute 1–5 stars across answers (`AudienceVoteService`)
  - Do not affect winner selection

## Tech Stack
- **Framework:** Ruby on Rails 8.0
- **Database:** SQLite3 (production-ready with solid_cache, solid_queue, solid_cable)
- **Web Server:** Puma with Thruster
- **Deployment:** Kamal with Docker containers
- **CI/CD:** GitHub Actions
- **Container Registry:** GitHub Container Registry (ghcr.io)
- Also using: Turbo, Stimulus, ActiveJob, Tailwind v4, ActionCable

## Developer Guidelines
- Frontend styling and design rules are in `.claude/rules/frontend-development.md` 
- Use @layer base, @layer components, @layer utilities as appropriate
- Place CSS animations in application.css

## Accessibility
- All new UI must meet WCAG 2.1 AA. Use `/a11y` to audit changes.
- Animations must have `@media (prefers-reduced-motion: reduce)` coverage

## Rails Conventions
- SolidQueue for background jobs (keep jobs idempotent)
- Services return `Data.define` result types (`Success`/`Failure`) — controllers pattern-match on them
- Turbo Streams broadcast to scoped channels: `"rooms:#{room.id}:<channel>"`

## Discord Activity / Iframe
- Discord's proxy follows HTTP redirects server-side and **strips the Authorization header** on redirect follows. This means the redirected request arrives at our app without the Bearer token, `discord_authenticated?` returns false, and Rails' default `X-Frame-Options: SAMEORIGIN` blocks the iframe.
- **Never use `redirect_to` in controller paths reachable by Discord players.** Use `turbo_nav_or_redirect_to` instead — it renders a Turbo Stream navigate action so navigation happens client-side where the Bearer token interceptor injects the auth header.
- Creator-only paths (e.g. `room_status_path`) can still use `redirect_to` since creators use a separate browser tab, not the Discord iframe.

## Testing
- Ensure tests pass after adding new features
- Add tests for new features
- Add tests intentionally- tests have 2 costs: 1) maintenance and 2) running them. Ensure critical code paths are covered.