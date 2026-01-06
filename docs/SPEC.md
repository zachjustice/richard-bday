# Goal
Generate a new look and feel for Blanksies website

## Website Overview
Blanksies is a collaborative fill-in-the-blank game played by friends.
Friends gather together in a shared space and follow the directives from the room status screen typically displayed on a TV or monitor that everyone can see.
Over the course of the game, players answer prompts, vote on their favorite answers, and the winning responses fill in the blanks of the story.
Prompts and stories are fun, playful, whimsical, humorous, witty, crude, sacrilegious, and/or scandalous.
The look and feel should be unique and different while aligning with the overall qualities of the game.

---

## Design Direction

### Overall Mood & Vibe
- **Playful Chaos** - Energetic, bold colors, dynamic shapes, party atmosphere
- **Intentional and Bold** - Create distinctive, production-grade frontend interfaces 
- Match implementation complexity to the aesthetic vision
- Interpret creatively and make unexpected choices that feel genuinely designed for the context

### Color Palette
**Bold Primary Colors** - Strong reds, yellows, blues inspired by pop art and children's toys
- Move completely away from purple and gradient overuse
- Think Jackbox Games energy meets Figma/Notion polish

### Typography
**Hand-drawn/Playful** - Slightly imperfect, marker-like letterforms with an informal feel
- Should feel human and approachable, not sterile
- Text-only branding for "Blanksies" name in a styled typeface

### Visual Motifs
**Doodles & Scribbles** - Hand-drawn visual elements throughout:
- Squiggles, stars, arrows, underlines, cross-outs
- Scribble decorations and accent marks
- Reinforces the fill-in-the-blank paper/writing theme

### The "Blank" Representation
**Classic Underline** - Traditional fill-in-the-blank underscore line
- Instantly recognizable as a blank to fill in
- Clean and clear for readability

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

### Design Inspiration
- **Jackbox Games** - Bold, colorful, TV-game-show polish with humor
- **Figma/Notion** - Clean, modern SaaS with playful illustrations
- Blend the party energy of Jackbox with the refined polish of modern SaaS

### Things to AVOID
- Gradients (especially purple gradients)
- Stock photos of people playing games
- Corporate/enterprise software aesthetic
- Generic LLM-generated UI patterns
- Overly polished or sterile feel

---

## Design Guide

### Philosophy
- **Purpose-driven naming**: Names describe entity purpose, not appearance
- **Self-contained components**: Effects built into components
- **Tailwind best practices**: Use `@layer components` / `@layer base`

### Style Guide for CSS / Tailwind
Following the Style Guide is critical.
* The primary header on the page should use the yellow text-shadow treatment
* Strongly perfer using tailwind utility classes whenever possible for readability and maintainability
* Only create new component classes in components.css when the pattern is repeated **multiple** times, or the classes are HIGHLY complex and VERY DIFFICULT to implement with the tailwind utility classes. 
* Only create template partials when necessary. Either because its needed for turbo streams, an oft repeated component, or HIGHLY complex component
* AVOID bouncing emoji's - its an overlayed cliche

### Theme Colors (application.css)
| Token | Value | Purpose |
|-------|-------|---------|
| `color-accent-primary` | #E63946 | Red - CTAs, alerts |
| `color-accent-secondary` | #2196F3 | Blue - links, secondary actions |
| `color-accent-tertiary` | #FFD60A | Yellow - highlights, accents |
| `color-accent-primary-light` | rgba(230, 57, 70, 0.1) | Light red backgrounds |
| `color-accent-secondary-light` | rgba(33, 150, 243, 0.1) | Light blue backgrounds |
| `color-accent-tertiary-light` | rgba(255, 214, 10, 0.15) | Light yellow backgrounds |
| `color-bg-page` | #FFF8E7 | Cream - page backgrounds |
| `color-ink` | #1A1A2E | Dark - text, borders, shadows |
| `color-ink-inverted` | #FFFFFF | Light - text/borders on dark backgrounds |

### Extended Palette (Rainbow)
| Token | Value | Purpose |
|-------|-------|---------|
| `color-accent-red` | #E63946 | Rainbow cycle - red |
| `color-accent-orange` | #FF6B35 | Rainbow cycle - orange |
| `color-accent-yellow` | #FFD60A | Rainbow cycle - yellow |
| `color-accent-green` | #4CAF50 | Rainbow cycle - green |
| `color-accent-blue` | #2196F3 | Rainbow cycle - blue |
| `color-accent-indigo` | #7C4DFF | Rainbow cycle - indigo |
| `color-accent-violet` | #E040FB | Rainbow cycle - violet |

### Tailwind Utilities (auto-generated)
- `text-ink`, `text-ink-inverted` - text colors
- `border-ink` - border colors
- `bg-accent-*` - background colors

### Component Classes (components.css)
| Class | Purpose |
|-------|---------|
| `.bg-page` | Page background with doodle pattern |
| `.btn-primary` | Primary CTA button with offset shadow |
| `.card-primary` | Main content card (8px shadow) |
| `.card-secondary` | Prominent callout card (4px shadow) - QR codes, announcements |
| `.card-subdued` | Softer secondary card with blur |
| `.badge-primary` | Playful badge/chip with 2px shadow - room codes, player items |
| `.step-indicator` | Numbered step circles |
| `.title-primary` | Logo/title with text-shadow |
| `.doodle-decoration` | Wiggle animation for SVGs |
| `.divider` | Horizontal divider with top border |
| `.stagger-animation` | Staggered entrance delays for list children |
| `.rainbow-cycle` | Cycling rainbow background colors (7 colors) |
| `.playful-tilt` | Varying rotation angles for chaos effect |

### Typography Classes
| Class | Purpose |
|-------|---------|
| `.title` | TODO |
| `.tagline` | Subheading/tagline text |
| `.heading` | Section headings |
| `.body` | Body text |
| `.label` | Bold labels |

### Form Classes
| Class | Purpose |
|-------|---------|
| `.form-input` | Text input with focus ring |
| `.form-label` | Uppercase bold label |
| `.form-header` | Form page title |
| `.form-subheader` | Form description text |

### Base Styles
- `<a>` elements: Animated underline on hover

### Shared Partials
| Partial | Purpose |
|---------|---------|
| `shared/_doodle_decorations` | Background SVG doodles (landing page) |
| `shared/_waiting_room_doodles` | Notebook-themed doodles (waiting room) |

---

## Room Status Design Principles

The room status page is displayed on a shared TV/monitor during gameplay. Design prioritizes:
- **Readability from a distance**: Large text, high contrast
- **Minimal chrome**: No header bar, floating controls only (branding top-left, settings top-right)
- **Player-centric focus**: Players are the main content in the waiting room

---

## TODO
- More doodles everywhere. More animations and more doodles
- Handle Turbo Stream case for rainbow-cycle (new players get correct color)