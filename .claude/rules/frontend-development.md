---
paths:
  - *.css
  - *.html.erb
  - *.js
---
# Frontend Development Rules

## Things to AVOID
- Gradients (especially purple gradients)
- Emoji's unless already existing or explicity specified
- Stock photos of people playing games
- Corporate/enterprise software aesthetic
- Generic LLM-generated UI patterns
- Overly polished or sterile feel

## Design Guide

### Philosophy
- **Purpose-driven naming**: Names describe the entity's purpose, not the appearance
- **Tailwind best practices**: idiomatic tailwind code
- **Playful Chaos**: The UI should embody the spirit of party games- energetic, colorful, playful, chaotic

### Style Guide for CSS / Tailwind
Following the Style Guide is critical.
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

### Accessibility
- Semantic HTML (`<nav>`, `<button>`, `<main>`) over generic `<div>`s
- Icon-only interactive elements need `aria-label` (not just `title`)
- Modals/drawers: `role="dialog"`, `aria-modal="true"`, focus trap via `concerns/focus_trap.js`, Escape key
- Form inputs must have associated `<label for="id">`
- Decorative elements: `aria-hidden="true"`
- Animations must be disabled in `prefers-reduced-motion` block in application.css

### Responsive Card Layout
Primary content cards (room status, stories/prompts index, editor settings) follow a strict responsive contract:

- **Card height** expands/shrinks with content — never a fixed height
- **Minimum height**: cards set a floor (e.g. `min-h-[20rem]`) so the page scrolls rather than the card collapsing to nothing on short viewports
- **Inner list scrolling**: when a card contains a list, the list scrolls internally so the card doesn't grow beyond the viewport

The pattern relies on two flex layers — breaking either causes regressions:
```
Card container:  flex-1 min-h-0 flex flex-col
Inner list:      flex-1 min-h-0 overflow-y-auto
```
`min-h-0` is critical — without it, flex children default to `min-height: auto` and overflow their parent. Every ancestor up to the viewport must also participate in the flex chain.

When modifying card layouts, verify in the browser at both tall and short viewport heights.

---

## Design Direction

### Overall Mood & Vibe
- **Playful Chaos** - Energetic, bold colors, dynamic shapes, party atmosphere
- **Intentional and Bold** - Create distinctive, production-grade frontend interfaces 
- Interpret creatively and make unexpected choices that feel genuinely designed for the context

### Color Palette
**Bold Primary Colors** - Strong reds, yellows, blues inspired by pop art and children's toys
- AVOID purple and gradient overuse
- USE strong strong colors defined in application.css

### Typography
**Hand-drawn/Playful** - Slightly imperfect, marker-like letterforms with an informal feel
- Should feel human, approachable, playful, not sterile
- Text-only branding for "Blanksies" name in a styled typeface with yellow highlight

### Visual Motifs
**Doodles & Scribbles** - Hand-drawn visual elements throughout:
- Including but not limited to squiggles, loop-de-loops, stars, arrows, underlines, cross-outs
- Scribble decorations and accent marks
- Reinforces the fill-in-the-blank paper/writing theme

### Background Treatment
**Repeating Pattern** - Doodle pattern background
- Consistent with the scribble/hand-drawn motif
- Adds energy and visual interest without overwhelming content

### Animation & Motion
**Bouncy & Fun** - Springy animations, wiggle effects, playful micro-interactions
- **Used intentionally** - animations should enhance, not distract
- Celebration moments for wins and reveals
- Subtle polish on transitions and hover states

### Target Audience
**Flexible** - Design should work across different content ratings
- The game content varies from family-friendly to adult
- Visual design should be universally appealing while hinting at playful irreverence
- This game is played with friends in the same room in front of a shared screen like TV or computer monitor

