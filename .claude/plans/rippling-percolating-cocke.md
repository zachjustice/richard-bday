# Plan: Refresh button status message

## Context
The refresh button in the Discord navbar currently only provides visual feedback by spinning the icon and briefly flashing it green/red. The user wants a brief text message explaining what's happening, with auto-dismiss and a11y support.

## Approach
Extend the existing `refresh_nav_controller.js` and navbar markup. Add a small inline status label next to the refresh button that shows contextual messages and auto-dismisses.

### 1. Add status message element to navbar
**File:** `app/views/shared/_discord_navbar.html.erb`

Add a `<span>` with `role="status"` and `aria-live="polite"` next to the refresh button inside the right-side `<div>`. This ensures screen readers announce the message when it changes without interrupting the user.

```erb
<span class="text-xs font-medium transition-opacity duration-300 opacity-0 whitespace-nowrap"
      data-refresh-nav-target="status"
      role="status"
      aria-live="polite"></span>
```

### 2. Update refresh controller to manage status messages
**File:** `app/javascript/controllers/refresh_nav_controller.js`

- Add `"status"` to `static targets`
- On click: show "Syncing..." in the status span (fade in via `opacity-100`)
- On success (no redirect): show "Up to date!" with green color, auto-dismiss after 2s
- On redirect: show "Navigating..." (stays visible as page transitions)
- On error: show "Sync failed" with red color, auto-dismiss after 2s
- Auto-dismiss = fade out via removing `opacity-100`, then clear text after the 300ms transition

## Verification
- Run `rails test` — no server-side changes so tests should pass
- Manually test: click refresh button, verify "Syncing..." appears, then "Up to date!" fades in/out
- Verify screen reader announces the status changes (role="status" + aria-live="polite")
- Verify `prefers-reduced-motion` — the `transition-opacity` is a simple fade, not a motion animation, so it's fine per WCAG guidelines
