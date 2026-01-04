# Tailwind CSS Migration Specification

## Executive Summary

This document outlines the complete plan to migrate the Blanksies project from a custom CSS system (BEM-inspired with design tokens) to **Tailwind CSS v4**. The migration will be **incremental** (one page at a time), prioritizing maintainability and developer experience while preserving the existing design and functionality.

**Technology Stack:**
- Rails 8.0.4 with Propshaft asset pipeline
- Tailwind CSS v4.1.18 via tailwindcss-rails gem
- CSS-first configuration using `@theme` directive (no JavaScript config)

## Current State Analysis

### Existing Architecture

**CSS Files (22 total):**
- Core: `application.css`, `design-tokens.css`, `base.css`, `components.css`, `utilities.css`
- Page-specific: `prompt-voting.css`, `prompt-answer.css`, `room-status.css`, `create-page.css`, etc. (17 files)

**Current System:**
- BEM-inspired naming (simplified): `.prompt-voting-card`, `.answer-option`, `.voting-header`
- CSS custom properties for design tokens (`--space-4`, `--color-primary-purple`, etc.)
- Hand-rolled utility classes (`.flex`, `.gap-4`, `.rounded-lg`, etc.)
- Page-specific stylesheets loaded via `stylesheet_link_tag` in templates

**Key Features to Preserve:**
- Gradient backgrounds and borders (`--gradient-primary-simple`, etc.)
- Custom animations (float, bounce, slideIn, slideUp)
- TV display mode (1240px+ scaling for large screens)
- Glass-morphism effects (backdrop-filter with rgba backgrounds)
- Scroll fade indicators (complex gradient backgrounds)
- Accessibility (prefers-reduced-motion support)

### Pain Points with Current System

1. **Fragmentation:** 22 CSS files with overlapping concerns
2. **Inconsistency:** Custom spacing/utilities don't match established scales (e.g., `--space-7: 1.75rem`)
3. **Maintenance:** Difficult to find where styles are defined
4. **DRY violations:** Similar patterns repeated across page-specific files

## Migration Strategy

### Philosophy

**Tailwind-First with Pragmatic Exceptions:**
- Default to Tailwind utilities in templates
- Use CSS classes for complex components (e.g., custom radio buttons with `:checked ~ .sibling` selectors)
- Create template partials for repeated patterns instead of CSS abstractions
- Use `@apply` sparingly, only for truly complex components

### Incremental Approach

**Migration Order:**
1. **Phase 0:** Setup & Foundation (Tailwind config via @theme, component CSS files)
2. **Phase 1:** Simple pages (create-page → login-page → sessions/new)
3. **Phase 2:** Medium complexity (prompt-voting → prompt-answer → prompt-waiting)
4. **Phase 3:** Complex pages (room-status with TV mode, results pages)
5. **Phase 4:** Shared components (flash messages, forms, modals)
6. **Phase 5:** Cleanup (remove old CSS files, update documentation)

**Per-Page Process:**
1. Identify components and patterns
2. Create Rails partials for reusable components
3. Convert layout utilities to Tailwind classes
4. Define component CSS classes using `@apply` where needed
5. Test manually across breakpoints and states
6. Comment out old CSS (keep file for reference)
7. Remove `stylesheet_link_tag` if page is fully migrated

## Technical Architecture

### Understanding Rails 8 + Propshaft + Tailwind v4

**Key Differences from Traditional Setups:**

1. **Propshaft vs Sprockets/Webpack:**
   - No bundling - each CSS file is a separate HTTP request
   - No preprocessing beyond Tailwind compilation
   - HTTP/2 multiplexing makes multiple requests efficient
   - **Important:** Custom CSS files using `@apply` must be `@import`ed into the Tailwind entry point to be processed

2. **Tailwind v4 vs v3:**
   - CSS-first configuration using `@theme` directive
   - No `tailwind.config.js` needed (though still supported)
   - Different `@layer` behavior
   - Simplified setup and faster builds

3. **tailwindcss-rails Gem:**
   - Compiles only `/app/assets/tailwind/application.css`
   - Output goes to `/app/assets/builds/tailwind.css` (auto-generated)
   - Watches for changes in development via `bin/rails tailwindcss:watch`
   - **Important:** Import component/animation CSS files into this entry point so `@apply` directives are processed

### File Structure (After Migration)

```
app/assets/
├── tailwind/
│   └── application.css          # Tailwind entry point: @imports components, @theme config with animations
├── stylesheets/
│   ├── application.css          # Legacy CSS import manifest (gradually remove imports)
│   ├── components.css           # Custom component classes with @apply (imported by tailwind/application.css)
│   └── [page-specific].css      # Legacy page CSS (comment out as pages are migrated)
└── builds/
    └── tailwind.css             # Auto-generated (gitignored) - contains processed components

app/views/
├── layouts/
│   └── application.html.erb     # Loads tailwind.css and application.css only
└── shared/
    └── _flash_messages.html.erb # (existing, migrate later)
```

**Key Architecture Points:**
- **No config/ directory needed** - Tailwind v4 uses CSS configuration
- **components.css** is `@import`ed into `tailwind/application.css` so `@apply` directives are processed by Tailwind
- **Animations are defined inside `@theme`** using Tailwind v4's native `@keyframes` support (no separate animations.css needed)
- **Layout only needs two stylesheet_link_tags:** `tailwind` (compiled output with components) and `application` (legacy CSS during migration)

### Tailwind v4 Configuration Using @theme

**app/assets/tailwind/application.css:**

```css
/* Import custom CSS files BEFORE tailwindcss so @apply directives are processed */
@import "../stylesheets/components.css";
@import "tailwindcss";

/* Tailwind v4 CSS-first configuration */
@theme {
  /* Brand Colors */
  --color-brand-purple: #667eea;
  --color-brand-deep-purple: #764ba2;
  --color-brand-pink: #f093fb;

  /* Semantic Colors */
  --color-error: #dc2626;
  --color-error-light: #fee2e2;
  --color-success: #22c55e;

  /* Custom Spacing (space-32 = 8rem) */
  --spacing-32: 8rem;

  /* Custom Border Radius */
  --radius-3xl: 24px;

  /* Custom Shadows */
  --shadow-button: 0 4px 15px rgba(102, 126, 234, 0.4);
  --shadow-2xl: 0 10px 40px rgba(0, 0, 0, 0.1);
  --shadow-3xl: 0 20px 60px rgba(102, 126, 234, 0.3);

  /* Gradients as CSS Variables (use with arbitrary values) */
  --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
  --gradient-primary-simple: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --gradient-primary-reverse: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
  --gradient-primary-tint: linear-gradient(135deg, rgba(102, 126, 234, 0.08) 0%, rgba(118, 75, 162, 0.08) 100%);

  /* Animations - Tailwind v4 native @keyframes inside @theme */
  --animate-gradient-shift: gradient-shift 15s ease infinite;
  @keyframes gradient-shift {
    0% { background-size: 400% 400%; background-position: 0% 50%; }
    50% { background-size: 400% 400%; background-position: 100% 50%; }
    100% { background-size: 400% 400%; background-position: 0% 50%; }
  }

  --animate-float: float 3s ease-in-out infinite;
  @keyframes float {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-10px); }
  }

  --animate-bounce-custom: bounce-custom 1s ease-in-out;
  @keyframes bounce-custom {
    0%, 100% { transform: translateY(0); }
    25% { transform: translateY(-20px); }
    50% { transform: translateY(0); }
    75% { transform: translateY(-10px); }
  }

  --animate-slide-in: slideIn 0.4s ease-out;
  @keyframes slideIn {
    from { opacity: 0; transform: translateX(-20px); }
    to { opacity: 1; transform: translateX(0); }
  }

  --animate-slide-up: slide-up 0.6s ease-out;
  @keyframes slide-up {
    from { opacity: 0; transform: translateY(30px); }
    to { opacity: 1; transform: translateY(0); }
  }
}

/* Disable animations for users who prefer reduced motion */
@media (prefers-reduced-motion: reduce) {
  .animate-float,
  .animate-bounce-custom,
  .animate-slide-in,
  .animate-slide-up,
  .animate-gradient-shift {
    animation: none;
  }
}

/* Global base styles */
html {
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}
```

**Usage in Templates:**

```erb
<!-- Use custom colors -->
<button class="bg-brand-purple text-white px-8 py-5 rounded-xl">

<!-- Use gradients as background-image (NOT bg-[var(...)]) -->
<div class="bg-(image:--gradient-primary) p-10">

<!-- Use custom spacing -->
<div class="p-32">  <!-- 8rem padding -->

<!-- Use custom shadows -->
<div class="shadow-button">

<!-- Use custom animations -->
<div class="animate-float">        <!-- Floating animation -->
<div class="animate-slide-up">     <!-- Slide up on mount -->
<div class="animate-gradient-shift"> <!-- Animated gradient background -->
```

**Important Tailwind v4 Syntax Notes:**
- For gradient CSS variables, use `bg-(image:--gradient-primary)` syntax
- The `bg-[var(--gradient-primary)]` syntax sets `background-color`, not `background-image`
- Gradients require `background-image` property to render correctly
- Animations are defined inside `@theme` using `--animate-*` variables and `@keyframes` blocks
- This generates utility classes like `animate-float`, `animate-slide-up`, etc.

### Component CSS Structure

**app/assets/stylesheets/components.css:**

```css
/* Component classes for complex patterns that need @apply or pseudo-selectors */

/* Card with gradient top border */
.card-primary {
  @apply relative bg-white rounded-3xl shadow-2xl overflow-hidden;
}

.card-primary::before {
  content: '';
  @apply absolute top-0 left-0 right-0 h-1.5;
  background: var(--gradient-primary-simple);
  border-radius: 24px 24px 0 0;
}

/* Gradient utility classes (since they're reused) */
.bg-gradient-primary {
  background: var(--gradient-primary);
}

.bg-gradient-primary-simple {
  background: var(--gradient-primary-simple);
}

.bg-gradient-primary-reverse {
  background: var(--gradient-primary-reverse);
}

.bg-gradient-primary-tint {
  background: var(--gradient-primary-tint);
}

/* Button - Primary */
.btn-primary {
  @apply px-8 py-5 text-lg font-bold text-white uppercase tracking-wider;
  @apply rounded-xl cursor-pointer transition-all border-none;
  background: var(--gradient-primary-simple);
  box-shadow: var(--shadow-button);
}

.btn-primary:hover {
  @apply -translate-y-1;
  background: var(--gradient-primary-reverse);
  box-shadow: 0 6px 25px rgba(102, 126, 234, 0.5);
}

.btn-primary:active {
  @apply -translate-y-0.5;
}

.btn-primary:focus {
  @apply outline-none ring-4 ring-brand-purple/30;
}

@media (prefers-reduced-motion: reduce) {
  .btn-primary:hover,
  .btn-primary:active {
    transform: none;
  }
}

/* Form Components */
.form-input {
  @apply w-full px-4 py-4 text-base font-medium bg-gray-50 border-2 border-gray-200;
  @apply rounded-xl outline-none transition-all;
}

.form-input:hover {
  @apply border-brand-purple bg-white;
}

.form-input:focus {
  @apply border-brand-purple bg-white ring-4 ring-brand-purple/10 -translate-y-px;
}

.form-input::placeholder {
  @apply text-gray-400 font-normal;
}

@media (prefers-reduced-motion: reduce) {
  .form-input:focus {
    transform: none;
  }
}

.form-label {
  @apply flex items-center gap-2 text-sm font-semibold uppercase tracking-wide;
}

/* Alert/Notice Messages */
.alert-message {
  @apply flex items-center gap-3 px-4 py-4 rounded-xl mb-6 text-sm font-medium border-2;
  background: linear-gradient(135deg, rgba(220, 38, 38, 0.1) 0%, rgba(220, 38, 38, 0.15) 100%);
  color: #dc2626;
  border-color: #fee2e2;
}

.notice-message {
  @apply flex items-center gap-3 px-4 py-4 rounded-xl mb-6 text-sm font-medium border-2;
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.1) 0%, rgba(34, 197, 94, 0.15) 100%);
  color: #15803d;
  border-color: rgba(34, 197, 94, 0.3);
}

/* Complex Radio Button Pattern (requires sibling selectors) */
.answer-option {
  @apply relative block cursor-pointer;
}

.answer-radio {
  @apply absolute opacity-0 w-0 h-0;
}

.answer-content {
  @apply relative flex items-center gap-4 px-5 py-5 rounded-xl border-2 transition-all;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
  border-color: rgba(102, 126, 234, 0.2);
}

.answer-checkmark {
  @apply flex-shrink-0 w-7 h-7 flex items-center justify-center;
  @apply border-2 border-brand-purple rounded-full text-transparent bg-white transition-all;
}

.answer-text {
  @apply flex-1 text-base font-medium leading-normal;
}

/* Hover state */
.answer-option:hover .answer-content {
  @apply border-brand-purple -translate-y-0.5;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

.answer-option:hover .answer-checkmark {
  @apply border-[3px] scale-110;
}

/* Checked state */
.answer-radio:checked ~ .answer-content {
  @apply border-brand-purple border-[3px];
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.2) 0%, rgba(118, 75, 162, 0.2) 100%);
  box-shadow: 0 4px 16px rgba(102, 126, 234, 0.3);
}

.answer-radio:checked ~ .answer-content .answer-checkmark {
  @apply border-brand-purple text-white scale-[1.15];
  background: var(--gradient-primary-simple);
}

.answer-radio:checked ~ .answer-content .answer-text {
  @apply font-bold;
}

.answer-radio:focus ~ .answer-content {
  @apply outline outline-3 outline-offset-2 outline-brand-purple/40;
}

@media (prefers-reduced-motion: reduce) {
  .answer-option:hover .answer-content,
  .answer-option:hover .answer-checkmark {
    transform: none;
  }
  .answer-radio:checked ~ .answer-content .answer-checkmark {
    transform: none;
  }
}

/* TV Mode - Scale fonts for large displays (1240px+) */
@media screen and (min-width: 1240px) {
  .tv-mode {
    font-size: 200%; /* Scale everything proportionally */
  }

  /* Fine-tune specific elements if needed */
  .tv-mode .room-code {
    font-size: 250%;
  }
}

/* Scroll Fade Indicators (too complex for inline utilities) */
.scroll-fade-indicators {
  background:
    /* Shadow Cover TOP */
    linear-gradient(white 30%, rgba(255, 255, 255, 0)) center top,
    /* Shadow Cover BOTTOM */
    linear-gradient(rgba(255, 255, 255, 0), white 70%) center bottom,
    /* Shadow TOP */
    radial-gradient(farthest-side at 50% 0, rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0)) center top,
    /* Shadow BOTTOM */
    radial-gradient(farthest-side at 50% 100%, rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0)) center bottom;

  background-repeat: no-repeat;
  background-size: 100% 40px, 100% 40px, 100% 14px, 100% 14px;
  background-attachment: local, local, scroll, scroll;
}

/* Glass Morphism Effects */
.glass-light {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
}

.glass-medium {
  background: rgba(255, 255, 255, 0.3);
  backdrop-filter: blur(10px);
}
```

**Note:** Animations are defined in `tailwind/application.css` inside `@theme` using Tailwind v4's native `@keyframes` support, not in a separate file.

### Asset Loading in Layout

**app/views/layouts/application.html.erb:**

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Blanksies</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%# Tailwind output (includes processed components.css and animations.css via @import) %>
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>

    <%# Legacy CSS - keep during migration, remove imports as pages are migrated %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

**Loading Order Explanation:**
1. `tailwind.css` loads first - this is the compiled output that includes:
   - Processed `components.css` (with `@apply` directives resolved)
   - Tailwind utilities, theme configuration, and animations (defined in `@theme`)
2. `application.css` loads second - legacy CSS manifest (gradually remove imports as pages migrate)

**Important:** Components are `@import`ed into `tailwind/application.css`, NOT loaded as separate stylesheet_link_tags. This is required for `@apply` directives to work. Animations are defined directly in `@theme` using Tailwind v4's native `@keyframes` support.

### Rails Component Partials

**app/views/shared/_card.html.erb:**

```erb
<%#
  Reusable card wrapper with gradient top border

  Usage:
    <%= render 'shared/card', animation: 'slide-up', class: 'p-10' do %>
      <p>Card content</p>
    <% end %>
%>

<div class="card-primary <%= local_assigns[:class] %> <%= "animate-#{local_assigns[:animation]}" if local_assigns[:animation] %>">
  <%= yield %>
</div>
```

**app/views/shared/_flash_messages.html.erb:**

```erb
<% if flash[:alert] %>
  <div class="alert-message animate-slide-in">
    <span class="text-xl flex-shrink-0">⚠️</span>
    <%= flash[:alert] %>
  </div>
<% end %>

<% if flash[:notice] %>
  <div class="notice-message animate-slide-in">
    <span class="text-xl flex-shrink-0">✓</span>
    <%= flash[:notice] %>
  </div>
<% end %>
```

## Migration Details by Complexity

### Simple Pages (Phase 1)

**Example: create-page.html.erb**

**Before:**
```erb
<%= stylesheet_link_tag "create-page", "data-turbo-track": "reload" %>

<div class="create-page">
  <div class="create-card">
    <%= tag.div(flash[:notice], class: "error-notice") if flash[:notice] %>

    <div class="create-content">
      <div class="emoji-header">✨📝🎨</div>
      <h1 class="create-title">Collaborative Fill-in-the-Blank Stories</h1>
      <p class="create-subtitle">Answer prompts with your friends to create stories!</p>

      <%= form_with url: "/rooms/create", method: :post, class: "create-form" do |form| %>
        <%= form.submit "New Game", class: "create-button" %>
      <% end %>

      <span class="join-game-link">
        <%= link_to "Join as a player instead", new_session_path %>
      </span>
    </div>
  </div>
</div>
```

**After:**
```erb
<%# No stylesheet_link_tag needed - using Tailwind utilities + component classes %>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#f0f4ff] to-[#f8f4ff] overflow-auto">
  <%= render 'shared/card', animation: 'slide-up', class: 'p-10 m-10 max-w-2xl w-full' do %>
    <%= render 'shared/flash_messages' %>

    <div class="flex flex-col items-center gap-8">
      <div class="text-6xl">✨📝🎨</div>
      <h1 class="text-4xl font-bold text-center">Collaborative Fill-in-the-Blank Stories</h1>
      <p class="text-lg text-gray-600 italic text-center">
        Answer prompts with your friends to create stories!
      </p>

      <%= form_with url: "/rooms/create", method: :post, class: "flex flex-col gap-4" do |form| %>
        <%= form.submit "New Game", class: "btn-primary" %>
      <% end %>

      <span class="text-sm">
        <%= link_to "Join as a player instead", new_session_path %>
      </span>
    </div>
  <% end %>

  <div class="absolute bottom-4 left-0 right-0 text-center text-sm text-gray-500">
    <%= link_to "copyright", copyright_path %> |
    <%= link_to "about", about_path %> |
    <%= link_to "bots", "/babble" %>
  </div>
</div>
```

**Migration Steps:**
1. Replace `.create-page` container with Tailwind utilities
2. Use `render 'shared/card'` partial instead of `.create-card`
3. Convert layouts to Tailwind flexbox utilities
4. Replace `.create-button` with `.btn-primary` component class
5. Test responsive behavior at 320px, 768px, 1024px
6. Comment out create-page.css content
7. Remove `stylesheet_link_tag`

### Medium Complexity (Phase 2)

**Example: prompt-voting.html.erb**

**Key Challenges:**
- Custom radio buttons with `:checked ~ .sibling` selectors
- Scroll fade indicators
- Form validation states
- Real-time Turbo Stream updates

**Strategy:**
- Use `.answer-option` component class (complex pseudo-selectors)
- Keep `.scroll-fade-indicators` utility class
- Template uses Tailwind for layout, component classes for complex UI

**Before:**
```erb
<div class="answers-list-wrapper">
  <div class="answers-list answers-list--fade">
    <%= form.collection_radio_buttons :answer_id, @answers, :id, :text do |b| %>
      <label class="answer-option">
        <%= b.radio_button class: "answer-radio" %>
        <div class="answer-content">
          <span class="answer-checkmark">✓</span>
          <p class="answer-text"><%= b.text %></p>
        </div>
      </label>
    <% end %>
  </div>
</div>
```

**After:**
```erb
<div class="flex flex-1 min-h-0">
  <div class="flex flex-1 min-h-0 overflow-y-auto flex-col gap-4 scroll-fade-indicators p-1">
    <%= form.collection_radio_buttons :answer_id, @answers, :id, :text do |b| %>
      <label class="answer-option">
        <%= b.radio_button class: "answer-radio" %>
        <div class="answer-content">
          <span class="answer-checkmark">✓</span>
          <p class="answer-text"><%= b.text %></p>
        </div>
      </label>
    <% end %>
  </div>
</div>
```

**Note:** `.answer-option`, `.answer-content`, `.answer-checkmark`, and `.answer-text` remain as component classes in components.css because they require complex pseudo-class selectors.

### Complex Pages (Phase 3)

**Example: room-status with TV mode**

**Key Challenges:**
- Multi-state components (answering, voting, results)
- TV mode font scaling at 1240px+
- Complex layouts with sidebars
- Real-time Turbo Stream updates
- QR code integration

**TV Mode Implementation:**

Instead of redefining every text class, use proportional font-size scaling:

```erb
<div class="status-content <%= 'tv-mode' if request.user_agent.include?('Large-Display') %>">
  <h1 class="text-2xl">This scales to 4rem on large screens</h1>
  <p class="text-base">This scales to 2rem on large screens</p>
</div>
```

The `.tv-mode` class in components.css uses `font-size: 200%` to scale all text proportionally.

**QR Code Layout:**

```erb
<div class="flex flex-col gap-1 text-gray-600 items-center">
  <div id="qr-code" class="w-full max-w-[200px] h-auto">
    <%# QR code SVG renders here %>
  </div>
  <span class="text-sm">Scan to join</span>
</div>
```

Simple flexbox layout prevents breaking, max-width ensures responsive behavior.

## Special Cases & Concerns

### 1. QR Code Styling in Waiting Room

**Concern:** Layout breaking around QR code component

**Solution:**
- Use simple Tailwind utilities: `flex flex-col gap-1 items-center`
- Max width constraint: `max-w-[200px]`
- Test with actual QR code generation
- Works responsively on all screen sizes

### 2. Game State Transitions (Turbo Streams)

**Concern:** Flash messages and animations during real-time updates

**Solution:**
- Animations work with Turbo Stream replacements (CSS is separate from HTML)
- Use animation classes (`.animate-slide-in`) instead of inline styles
- Test that Turbo Stream `replace` actions preserve Tailwind classes
- Consider `data-turbo-permanent` for elements that shouldn't re-render

**Example Turbo Stream:**
```erb
<turbo-stream action="replace" target="flash-messages">
  <template>
    <%= render 'shared/flash_messages' %>
  </template>
</turbo-stream>
```

### 3. TV Display Mode Scaling

**Concern:** Scale all fonts 2x on 1240px+ displays

**Solution:**
- Use `.tv-mode` class with `font-size: 200%` in media query
- All child text scales proportionally (uses relative units)
- Simple to maintain, works with Tailwind text utilities
- Fine-tune specific elements if needed

**Why this works better than redefining every class:**
- Less CSS to maintain
- Works with any Tailwind text class
- Easier to adjust scaling factor
- Respects relative units and inheritance

## Testing Strategy

### Per-Page Testing Checklist

- [ ] Visual regression: Screenshots at 320px, 768px, 1024px, 1440px, 2560px (TV)
- [ ] Hover states work on all interactive elements
- [ ] Focus states visible for keyboard navigation
- [ ] Animations disabled with `prefers-reduced-motion: reduce`
- [ ] Turbo Stream updates preserve styling
- [ ] Flash messages animate correctly
- [ ] Forms submit and validate properly
- [ ] Custom radio/checkbox inputs work
- [ ] Scroll behavior correct (fade indicators, overflow)
- [ ] TV mode scaling works at 1240px+

### Browser Testing

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

### Accessibility Testing

- Keyboard navigation works
- Screen reader compatibility
- Color contrast sufficient (WCAG AA)
- Focus indicators visible
- Motion reduced when preferred

## Migration Phases in Detail

### Phase 0: Setup & Foundation (Est: 2 hours)

**Tasks:**

1. **Configure Tailwind v4 in `/app/assets/tailwind/application.css`:**
   - Add `@theme` directive with brand colors, custom spacing, shadows
   - Define gradient CSS variables
   - Define animations inside `@theme` using `--animate-*` variables and `@keyframes` blocks
   - Add `prefers-reduced-motion` support outside `@theme`
   - Test compilation: `bin/rails tailwindcss:build`

2. **Create `/app/assets/stylesheets/components.css`:**
   - Button components (`.btn-primary`)
   - Card components (`.card-primary`)
   - Form components (`.form-input`, `.form-label`)
   - Alert/notice messages
   - Complex radio buttons (`.answer-option`, etc.)
   - TV mode scaling
   - Scroll fade indicators

3. **Update `/app/views/layouts/application.html.erb`:**
   - Load Tailwind and application CSS files
   - Set up `yield :stylesheets` for page-specific CSS

4. **Create Rails partials:**
   - `app/views/shared/_card.html.erb`
   - `app/views/shared/_flash_messages.html.erb`

5. **Test setup:**
   - Start Rails server: `bin/dev`
   - Verify Tailwind compiles without errors
   - Check no visual regressions on existing pages
   - Verify all CSS files load in correct order

**Deliverables:**
- Working Tailwind v4 configuration with animations defined in `@theme`
- Component CSS file with `@apply` patterns
- Shared partials created
- No visual regressions on existing pages

### Phase 1: Simple Pages (Est: 4 hours)

**Pages:**
1. rooms/create (create-page.css)
2. sessions/new (login-page.css)
3. about/show, copyright/show (minimal styles)

**Per-Page Process:**
1. Read current ERB template
2. Identify all custom classes
3. Map to Tailwind utilities or component classes
4. Update template with new classes
5. Test appearance and functionality
6. Comment out old CSS file
7. Remove `stylesheet_link_tag`

**Success Criteria:**
- Visually identical to before
- No console errors
- Forms work correctly
- Responsive behavior preserved

### Phase 2: Medium Complexity (Est: 8 hours)

**Pages:**
1. prompts/voting (prompt-voting.css)
2. prompts/show (prompt-answer.css)
3. prompts/waiting (prompt-waiting.css)
4. prompts/results (prompt-results.css)

**Key Challenges:**
- Custom radio buttons (keep as component classes)
- Scroll fade indicators (use utility class)
- Form handling with Stimulus
- Turbo Stream updates

**Process:**
1. Migrate layout to Tailwind utilities
2. Keep complex component classes
3. Test form submissions thoroughly
4. Test Turbo Stream updates
5. Verify animations work
6. Comment out CSS file

### Phase 3: Complex Pages (Est: 12 hours)

**Pages:**
1. rooms/status (room-status.css) - Most complex
2. rooms/show (room-lobby.css)
3. rooms/waiting_for_new_game (waiting-for-new-game.css)
4. sessions/editor (story-editor.css)

**Key Challenges:**
- Multi-state components
- TV mode scaling
- Complex layouts
- QR code integration
- Background music controls

**Process:**
1. Create partials for reusable components
2. Apply `.tv-mode` class for large displays
3. Use Tailwind for layout, components for complex UI
4. Test all game states
5. Verify Turbo Stream targets preserved

### Phase 4: Shared Components (Est: 6 hours)

**Components:**
1. Flash messages (verify all usages)
2. Modals (settings-modal, blank-modal)
3. Countdown timer
4. Music player
5. Fun facts sidebar
6. Game progress sidebar

**Process:**
1. Extract to shared partials where possible
2. Use component classes for complex UI
3. Test in all contexts
4. Ensure Stimulus controllers work

### Phase 5: Cleanup (Est: 4 hours)

**Tasks:**
1. Delete all commented-out CSS files
2. Verify no references to old CSS files
3. Test production build
4. Update documentation

**Files to Delete:**
- design-tokens.css
- base.css (old)
- components.css (old)
- utilities.css (old)
- All page-specific CSS files (17 files)

**Files to Keep:**
- app/assets/tailwind/application.css (includes @theme config with animations)
- app/assets/stylesheets/components.css (component classes with @apply)

## Production Build

### Tailwind CSS Production

The tailwindcss-rails gem handles production optimization automatically:

```bash
# Test production build
RAILS_ENV=production bin/rails tailwindcss:build

# Verify output size
ls -lh app/assets/builds/tailwind.css

# Expected: ~20-30KB gzipped (Tailwind v4 is smaller)
```

**Automatic Optimizations:**
- Unused utilities purged
- CSS minified
- Source maps omitted

### Asset Precompilation

Propshaft handles CSS serving in production:

```bash
# Precompile assets
bin/rails assets:precompile

# Assets served from public/assets/
```

## Rollback Plan

If issues arise:

**Revert specific page:**
1. Uncomment old CSS file
2. Re-add `stylesheet_link_tag` to template
3. Revert ERB template (use `git checkout`)

**Full rollback:**
1. `git revert` migration commits
2. Restore old `application.css`
3. Keep Tailwind setup (no harm)

**Note:** Incremental approach minimizes rollback risk.

## Documentation Updates

### Update docs/CSS_CONVENTIONS.md

Replace with Tailwind v4 conventions:

```markdown
# CSS Conventions

This project uses **Tailwind CSS v4** with minimal custom CSS.

## File Structure

```
app/assets/
├── tailwind/
│   └── application.css      # @theme config (with animations) + Tailwind import
├── stylesheets/
│   └── components.css       # Custom component classes with @apply
└── builds/
    └── tailwind.css         # Auto-generated
```

## Styling Approach

### Default: Tailwind Utilities in Templates

```erb
<div class="flex items-center gap-4 px-6 py-4 bg-white rounded-xl shadow-md">
  <h2 class="text-2xl font-bold">Title</h2>
</div>
```

### Component Classes for Complex Patterns

Use for:
- Repeated patterns (buttons, cards, forms)
- Pseudo-selectors (`:hover`, `:checked ~ .sibling`)
- Complex multi-state interactions

```erb
<button class="btn-primary">Submit</button>

<label class="answer-option">
  <input type="radio" class="answer-radio">
  <div class="answer-content">...</div>
</label>
```

### Rails Partials for Reusable Components

```erb
<%= render 'shared/card', class: 'p-8' do %>
  <p>Card content</p>
<% end %>
```

## Tailwind v4 Configuration

Use `@theme` in `app/assets/tailwind/application.css`:

```css
@theme {
  --color-brand-purple: #667eea;
  --spacing-32: 8rem;
}
```

Then use in templates:

```erb
<div class="bg-brand-purple p-32">
```

## Asset Loading with Propshaft

Propshaft serves files separately (no bundling):

```erb
<%= stylesheet_link_tag "tailwind" %>      <!-- Compiled output with components + animations -->
<%= stylesheet_link_tag "application" %>   <!-- Legacy CSS during migration -->
```

Components are `@import`ed into `tailwind/application.css` so `@apply` works.
Animations are defined in `@theme` using Tailwind v4's native `@keyframes` support.

## Best Practices

1. **Prefer utilities** - Use Tailwind classes unless pattern is too complex
2. **Create partials** - Extract repeated markup to shared partials
3. **Use semantic names** - `.btn-primary`, not `.purple-button`
4. **Minimal @apply** - Only for complex pseudo-selectors
5. **Test responsive** - Check mobile, tablet, desktop, TV (1240px+)
6. **Respect motion** - Include `prefers-reduced-motion` media query for animations
```

### Create docs/TAILWIND_MIGRATION.md

New file documenting migration:

```markdown
# Tailwind CSS Migration Guide

Migration from custom CSS to **Tailwind CSS v4**.

## Technology Stack

- Rails 8.0.4 + Propshaft
- Tailwind CSS v4.1.18 (via tailwindcss-rails gem)
- CSS-first configuration (@theme directive)

## Migration Timeline

- **Phase 0:** Setup & Foundation ⏳
- **Phase 1:** Simple Pages ⏳
- **Phase 2:** Medium Complexity ⏳
- **Phase 3:** Complex Pages ⏳
- **Phase 4:** Shared Components ⏳
- **Phase 5:** Cleanup ⏳

## Key Decisions

1. **Tailwind v4 @theme** - CSS config instead of JavaScript
2. **Propshaft serving** - Multiple CSS files OK (HTTP/2)
3. **Component classes** - For complex pseudo-selectors only
4. **Rails partials** - For markup + style reusability
5. **TV mode scaling** - Proportional font-size, not class redefinition

## Special Cases

### TV Display Mode

**Challenge:** Scale fonts 2x on 1240px+ displays

**Solution:** `.tv-mode { font-size: 200%; }` with media query

### Scroll Fade Indicators

**Challenge:** Complex gradient backgrounds

**Solution:** `.scroll-fade-indicators` utility class (too complex for inline)

### Custom Radio Buttons

**Challenge:** `:checked ~ .sibling` selectors

**Solution:** Component classes with @apply

## Lessons Learned

- Tailwind v4 is simpler than v3 (CSS config)
- Propshaft's separate file serving works well
- Component classes still needed for complex CSS
- Partials reduce duplication better than CSS abstractions
```

## Appendix: Tailwind v4 vs v3

### Key Differences

| Feature | Tailwind v3 | Tailwind v4 |
|---------|-------------|-------------|
| Config | `tailwind.config.js` (JS) | `@theme` in CSS |
| Layers | `@layer` works anywhere | Only in main CSS file |
| Import | `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| Animations | Separate file or config.js | `@keyframes` inside `@theme` |
| Size | ~3.5MB uncompiled | ~2MB uncompiled |
| Speed | Fast | Faster (Oxide engine) |
| Variants | `motion-reduce:` prefix | Same |

### Migration from v3

If following v3 documentation, update:

**v3:**
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: { brand: { purple: '#667eea' } }
    }
  }
}
```

**v4:**
```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";

@theme {
  --color-brand-purple: #667eea;
}
```

## Conclusion

This specification provides a production-ready plan for migrating to Tailwind CSS v4 while:

- Preserving all functionality and design
- Improving maintainability
- Reducing CSS complexity
- Using incremental, low-risk approach
- Leveraging Rails 8 + Propshaft + Tailwind v4 best practices

**Total Estimated Time:** 36 hours across 5 phases
