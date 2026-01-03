# Tailwind CSS Migration Specification

## Executive Summary

This document outlines the complete plan to migrate the Blanksies project from a custom CSS system (BEM-inspired with design tokens) to Tailwind CSS. The migration will be **incremental** (one page at a time), prioritizing maintainability and developer experience while preserving the existing design and functionality.

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
3. **Maintenance:** Updating repeated styles across files, hardcoded values
4. **DRY violations:** Similar patterns repeated across page-specific files

## Migration Strategy

### Philosophy

**Tailwind-First with Pragmatic Exceptions:**
- Default to Tailwind utilities in templates
- Use CSS classes for complex components (e.g., custom radio buttons with `:checked ~ .sibling` selectors)
- Create template partials for repeated patterns instead of CSS abstractions

### Incremental Approach

**Migration Order:**
1. **(DONE) Phase 0:** Setup & Foundation (Tailwind config, base layers)
2. **(WIP) Phase 1:** Simple pages (create-page → login-page → sessions/new)
3. **Phase 2:** Medium complexity (prompt-voting → prompt-answer → prompt-waiting)
4. **Phase 3:** Complex pages (room-status with TV mode, results pages)
5. **Phase 4:** Shared components (flash messages, forms, modals)
6. **Phase 5:** Cleanup (remove old CSS files, update documentation)

**Per-Page Process:**
1. Identify components and patterns
2. Create Rails partials for reusable components
3. Convert layout utilities to Tailwind classes
4. Define component CSS classes using `@apply` where needed
5. Test manually
6. Comment out old CSS (keep file for reference)
7. Remove `stylesheet_link_tag` if page is fully migrated

## Technical Architecture

### File Structure (After Migration)

```
app/assets/
├── stylesheets/
│   ├── application.css          # Main Tailwind entry (KEEP)
│   └── tailwind/
│       ├── base.css             # @layer base customizations
│       ├── components.css       # @layer components (cards, buttons, forms)
│       └── utilities.css        # @layer utilities (scroll-fade, gradients)
├── builds/
│   └── tailwind.css             # Generated output
└── tailwind/
    └── application.css          # @import "tailwindcss"

config/
└── tailwind.config.js           # Theme extensions, custom colors, spacing

app/views/
├── shared/
│   ├── _flash_messages.html.erb
│   ├── _card.html.erb           # Reusable card wrapper
│   └── _form_input.html.erb     # Form field component
└── [page-specific views]        # Use Tailwind utilities + partials
```

### Tailwind Configuration

**tailwind.config.js:**

```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.rb'
  ],

  theme: {
    extend: {
      colors: {
        brand: {
          purple: '#667eea',
          'deep-purple': '#764ba2',
          pink: '#f093fb'
        },
        // Semantic colors
        error: {
          DEFAULT: '#dc2626',
          light: '#fee2e2'
        },
        success: '#22c55e'
      },

      spacing: {
        // Add custom space-32 (8rem) - space-7 will use space-6 or space-8
        32: '8rem'
      },

      fontSize: {
        // Preserve any unique sizes not in Tailwind
        // Most will map to Tailwind's defaults
      },

      borderRadius: {
        '3xl': '24px',
        'full': '20px'  // Note: custom full radius (not 9999px)
      },

      boxShadow: {
        'button': '0 4px 15px rgba(102, 126, 234, 0.4)',
        '2xl': '0 10px 40px rgba(0, 0, 0, 0.1)',
        '3xl': '0 20px 60px rgba(102, 126, 234, 0.3)'
      },

      animation: {
        'float': 'float 3s ease-in-out infinite',
        'bounce-custom': 'bounce-custom 1s ease-in-out',
        'slide-in': 'slideIn 0.4s ease-out',
        'slide-up': 'slideUp 0.6s ease-out'
      },

      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' }
        },
        'bounce-custom': {
          '0%, 100%': { transform: 'translateY(0)' },
          '25%': { transform: 'translateY(-20px)' },
          '50%': { transform: 'translateY(0)' },
          '75%': { transform: 'translateY(-10px)' }
        },
        slideIn: {
          from: { opacity: '0', transform: 'translateX(-20px)' },
          to: { opacity: '1', transform: 'translateX(0)' }
        },
        slideUp: {
          from: { opacity: '0', transform: 'translateY(30px)' },
          to: { opacity: '1', transform: 'translateY(0)' }
        }
      },

      backdropBlur: {
        xs: '2px'
      }
    }
  },

  plugins: [],

  // IMPORTANT: Disable purge during migration
  safelist: process.env.RAILS_ENV === 'production' ? [] : ['*']
}
```

### CSS Layer Structure

**app/assets/tailwind/application.css:**
```css
@import "tailwindcss";
```

**app/assets/stylesheets/tailwind/base.css:**
```css
@layer base {
  html {
    @apply text-base font-normal leading-normal;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  body {
    @apply min-h-screen flex flex-col;
  }

  h1, h2, h3, h4, h5, h6 {
    @apply font-semibold mb-2 leading-tight;
  }

  a {
    @apply text-blue-500 no-underline hover:underline;
  }

  /* TV Mode - Scale fonts for large displays */
  @media screen and (min-width: 1240px) {
    .tv-mode {
      --scale-factor: 2;
      /* Applied to specific containers, not globally */
    }
  }
}
```

**app/assets/stylesheets/tailwind/components.css:**
```css
@layer components {
  /* Card Pattern - Reusable card with gradient top border */
  .card-primary {
    @apply relative bg-white rounded-3xl shadow-2xl overflow-hidden;
  }

  .card-primary::before {
    content: '';
    @apply absolute top-0 left-0 right-0 h-1.5;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 24px 24px 0 0;
  }

  /* Gradient Utilities */
  .bg-gradient-primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
  }

  .bg-gradient-primary-simple {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  .bg-gradient-primary-reverse {
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
  }

  .bg-gradient-primary-tint {
    background: linear-gradient(135deg, rgba(102, 126, 234, 0.08) 0%, rgba(118, 75, 162, 0.08) 100%);
  }

  /* Form Components */
  .form-input {
    @apply w-full px-4 py-4 text-base font-medium bg-gray-50 border-2 border-gray-200
           rounded-xl outline-none transition-all;
    @apply hover:border-brand-purple hover:bg-white;
    @apply focus:border-brand-purple focus:bg-white focus:shadow-[0_0_0_4px_rgba(102,126,234,0.1)]
           focus:translate-y-[-1px];
  }

  .form-input::placeholder {
    @apply text-gray-400 font-normal;
  }

  .form-label {
    @apply flex items-center gap-2 text-sm font-semibold uppercase tracking-wide;
  }

  /* Button - Primary */
  .btn-primary {
    @apply px-8 py-5 text-lg font-bold text-white uppercase tracking-wider
           rounded-xl cursor-pointer transition-all border-none;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  }

  .btn-primary:hover {
    @apply motion-safe:translate-y-[-3px];
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
    box-shadow: 0 6px 25px rgba(102, 126, 234, 0.5);
  }

  .btn-primary:active {
    @apply motion-safe:translate-y-[-1px];
  }

  .btn-primary:focus {
    @apply outline-none;
    box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.3), 0 4px 15px rgba(102, 126, 234, 0.4);
  }

  /* Alert/Notice Messages */
  .alert-message {
    @apply flex items-center gap-3 px-4 py-4 rounded-xl mb-6 text-sm font-medium
           border-2 motion-safe:animate-slide-in;
    background: linear-gradient(135deg, rgba(220, 38, 38, 0.1) 0%, rgba(220, 38, 38, 0.15) 100%);
    color: #dc2626;
    border-color: #fee2e2;
  }

  .notice-message {
    @apply flex items-center gap-3 px-4 py-4 rounded-xl mb-6 text-sm font-medium
           border-2 motion-safe:animate-slide-in;
    background: linear-gradient(135deg, rgba(34, 197, 94, 0.1) 0%, rgba(34, 197, 94, 0.15) 100%);
    color: #15803d;
    border-color: rgba(34, 197, 94, 0.3);
  }

  /* Complex Radio Button Pattern (from prompt-voting.css) */
  .answer-option {
    @apply relative block cursor-pointer;
  }

  .answer-radio {
    @apply absolute opacity-0 w-0 h-0;
  }

  .answer-content {
    @apply relative flex items-center gap-4 px-5 py-5 rounded-xl
           border-2 transition-all;
    background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
    border-color: rgba(102, 126, 234, 0.2);
  }

  .answer-checkmark {
    @apply flex-shrink-0 w-7 h-7 flex items-center justify-center
           border-2 border-brand-purple rounded-full text-transparent
           bg-white transition-all;
  }

  .answer-text {
    @apply flex-1 text-base font-medium leading-normal;
  }

  /* Hover state */
  .answer-option:hover .answer-content {
    @apply border-brand-purple motion-safe:translate-y-[-2px];
    background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  }

  .answer-option:hover .answer-checkmark {
    @apply border-[3px] motion-safe:scale-110;
  }

  /* Checked state */
  .answer-radio:checked ~ .answer-content {
    @apply border-brand-purple border-[3px];
    background: linear-gradient(135deg, rgba(102, 126, 234, 0.2) 0%, rgba(118, 75, 162, 0.2) 100%);
    box-shadow: 0 4px 16px rgba(102, 126, 234, 0.3);
  }

  .answer-radio:checked ~ .answer-content .answer-checkmark {
    @apply border-brand-purple text-white motion-safe:scale-[1.15];
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  .answer-radio:checked ~ .answer-content .answer-text {
    @apply font-bold;
  }

  .answer-radio:focus ~ .answer-content {
    @apply outline outline-3 outline-offset-2;
    outline-color: rgba(102, 126, 234, 0.4);
  }

  /* TV Mode Components */
  .tv-mode .text-base { font-size: 2rem; }
  .tv-mode .text-sm { font-size: 1rem; }
  .tv-mode .text-lg { font-size: 2.5rem; }
  .tv-mode .text-xl { font-size: 2.75rem; }
  .tv-mode .text-2xl { font-size: 3rem; }
  .tv-mode .text-3xl { font-size: 4rem; }
  .tv-mode .text-4xl { font-size: 5rem; }
  .tv-mode .text-5xl { font-size: 6rem; }
  .tv-mode .text-6xl { font-size: 8rem; }
}
```

**app/assets/stylesheets/tailwind/utilities.css:**
```css
@layer utilities {
  /* Scroll Fade Indicators */
  .scroll-fade-indicators {
    --fade-size: 32px;

    background:
      /* Shadow Cover TOP */
      linear-gradient(
        white 30%,
        rgba(255, 255, 255, 0)
      ) center top,

      /* Shadow Cover BOTTOM */
      linear-gradient(
        rgba(255, 255, 255, 0),
        white 70%
      ) center bottom,

      /* Shadow TOP */
      radial-gradient(
        farthest-side at 50% 0,
        rgba(0, 0, 0, 0.2),
        rgba(0, 0, 0, 0)
      ) center top,

      /* Shadow BOTTOM */
      radial-gradient(
        farthest-side at 50% 100%,
        rgba(0, 0, 0, 0.2),
        rgba(0, 0, 0, 0)
      ) center bottom;

    background-repeat: no-repeat;
    background-size: 100% 40px, 100% 40px, 100% 14px, 100% 14px;
    background-attachment: local, local, scroll, scroll;
  }

  /* Glass Morphism Helpers */
  .glass-light {
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(10px);
  }

  .glass-medium {
    background: rgba(255, 255, 255, 0.3);
    backdrop-filter: blur(10px);
  }
}
```

### Rails Component Partials

**app/views/shared/_card.html.erb:**
```erb
<%#
  Reusable card wrapper with gradient top border
  Usage: <%= render 'shared/card', animation: 'slide-up' do %>
           <p>Card content</p>
         <% end %>
%>

<div class="card-primary <%= local_assigns[:class] %> <%= "motion-safe:animate-#{local_assigns[:animation]}" if local_assigns[:animation] %>">
  <%= yield %>
</div>
```

**app/views/shared/_flash_messages.html.erb:**
```erb
<% if flash[:alert] %>
  <div class="alert-message">
    <span class="text-xl flex-shrink-0">⚠️</span>
    <%= flash[:alert] %>
  </div>
<% end %>

<% if flash[:notice] %>
  <div class="notice-message">
    <span class="text-xl flex-shrink-0">✓</span>
    <%= flash[:notice] %>
  </div>
<% end %>
```

**app/views/shared/_form_input.html.erb:**
```erb
<%#
  Styled form input component
  Usage: <%= render 'shared/form_input',
               form: form,
               field: :text,
               label: 'Answer',
               type: 'text_area',
               placeholder: '...' %>
%>

<div class="flex flex-col gap-2">
  <% if local_assigns[:label] %>
    <%= label_tag local_assigns[:field], class: 'form-label' do %>
      <%= local_assigns[:label] %>
    <% end %>
  <% end %>

  <% if local_assigns[:type] == 'text_area' %>
    <%= form.text_area local_assigns[:field],
          class: 'form-input',
          placeholder: local_assigns[:placeholder],
          **local_assigns.except(:form, :field, :label, :type, :placeholder) %>
  <% else %>
    <%= form.text_field local_assigns[:field],
          class: 'form-input',
          placeholder: local_assigns[:placeholder],
          **local_assigns.except(:form, :field, :label, :type, :placeholder) %>
  <% end %>
</div>
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
    </div>
  </div>
</div>
```

**After:**
```erb
<%# No stylesheet_link_tag needed - using Tailwind utilities %>

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
1. Replace `.create-page` container with Tailwind utilities (min-h-screen, flex, etc.)
2. Use `render 'shared/card'` partial instead of `.create-card` class
3. Convert `.create-content` layout to flexbox utilities
4. Replace button classes with `.btn-primary` component
5. Test responsive behavior
6. Comment out create-page.css content
7. Remove `stylesheet_link_tag`

### Medium Complexity (Phase 2)

**Example: prompt-voting.html.erb**

**Key Challenges:**
- Custom radio button styling with sibling selectors
- Scroll fade indicators
- Form validation states

**Strategy:**
- Use `.answer-option` component class (defined in components.css with `@apply`)
- Keep complex `:checked ~ .content` selectors in CSS
- Use `scroll-fade-indicators` utility class
- Template structure stays similar but uses Tailwind for layout

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

**Note:** `.answer-option`, `.answer-content`, `.answer-checkmark`, and `.answer-text` remain as component classes because they require complex pseudo-class selectors that can't be done with utilities alone.

### Complex Pages (Phase 3)

**Example: room-status with TV mode**

**Key Challenges:**
- Header with three-column layout (header-left, header-center, header-right)
- TV mode scaling at 1240px+ breakpoint
- Multiple nested components
- Real-time Turbo Stream updates

**Strategy:**
1. Create `_status_header.html.erb` partial for header component
2. Apply `.tv-mode` class to container div for TV scaling
3. Use hybrid approach: Tailwind for layout, component classes for complex styling
4. Ensure Turbo Stream target IDs preserved during migration

**TV Mode Implementation:**

**Template:**
```erb
<div class="status-content <%= 'tv-mode' if large_screen? %>">
  <%# Content scales automatically via .tv-mode class %>
  <h1 class="text-2xl">This will be 3rem on TV mode</h1>
</div>
```

**Helper (if needed):**
```ruby
# app/helpers/application_helper.rb
def large_screen?
  # Can use JavaScript detection or default to false for SSR
  false
end
```

**Media Query (in components.css):**
```css
@media screen and (min-width: 1240px) {
  .tv-mode .text-base { font-size: 2rem; }
  /* ... other scalings ... */
}
```

## Special Cases & Concerns

### 1. QR Code Styling in Waiting Room

**Concern:** Layout breaking around QR code component

**Solution:**
- Keep QR code container simple with Tailwind utilities
- Use flexbox centering: `flex flex-col gap-1 items-center`
- Test with actual QR code generation to ensure responsive behavior
- Max width constraint: `max-w-[200px]`

**Example:**
```erb
<div class="flex flex-col gap-1 text-gray-600 items-center">
  <div id="qr-code" class="w-full max-w-[200px] h-auto">
    <%# QR code renders here %>
  </div>
  <span class="text-sm">Scan to join</span>
</div>
```

### 2. Game State Transitions (Turbo Streams)

**Concern:** Flash messages and animations during real-time updates

**Solution:**
- Ensure flash message animations work with Turbo Stream replacements
- Use `motion-safe:` prefix for all animations to respect prefers-reduced-motion
- Test Turbo Stream updates don't break Tailwind class application
- Consider using `data-turbo-permanent` for elements that shouldn't re-render

**Flash Message Testing:**
```erb
<%# In Turbo Stream response %>
<turbo-stream action="replace" target="flash-messages">
  <template>
    <%= render 'shared/flash_messages' %>
  </template>
</turbo-stream>
```

**Animation Timing:**
- Ensure `animate-slide-in` duration (0.4s) is fast enough for real-time updates
- May need to reduce animation duration for frequently updating elements

### 3. TV Display Mode Scaling

**Concern:** Unusual 1240px+ media query that scales ALL fonts

**Solution:**
- Create `.tv-mode` wrapper class
- Define font size overrides in `@layer components`
- Apply class conditionally (or use JavaScript detection)
- Test with actual large display if possible

**Implementation Notes:**
- Don't use responsive utilities (`2xl:text-5xl`) - too verbose and hard to maintain
- Keep all scaling in one place (components.css) for easy adjustment
- Document that TV mode is an all-or-nothing class application

## Testing Strategy

### Per-Page Testing Checklist

- [ ] Visual regression: Compare before/after screenshots at 320px, 768px, 1024px, 1440px
- [ ] Hover states work on all interactive elements
- [ ] Focus states visible for keyboard navigation
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Turbo Stream updates don't break styling
- [ ] Flash messages appear and animate correctly
- [ ] Forms submit and validate properly
- [ ] Custom radio/checkbox inputs work (if applicable)
- [ ] Scroll behavior works (fade indicators, overflow, etc.)
- [ ] TV mode scaling works at 1240px+ (if applicable)

### Browser Testing

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

### Accessibility Testing

- Keyboard navigation works
- Screen reader compatibility (aria labels preserved)
- Sufficient color contrast (run axe DevTools)
- Focus indicators visible
- Motion reduced when `prefers-reduced-motion: reduce`

## Migration Phases in Detail

### Phase 0: Setup & Foundation (Est: 2 hours)

**Tasks:**
1. Create `config/tailwind.config.js` with theme extensions
2. Create `app/assets/stylesheets/tailwind/` directory structure
3. Set up base.css, components.css, utilities.css in tailwind/ folder
4. Configure Tailwind to disable purge (set safelist)
5. Update `app/assets/stylesheets/application.css` to import new structure
6. Test that Tailwind builds correctly (`bin/rails tailwindcss:build`)
7. Verify no visual regressions on existing pages

**Deliverables:**
- Working Tailwind configuration
- Base layer CSS files with common patterns
- Component classes defined (card-primary, btn-primary, form-input)
- Utility classes defined (scroll-fade-indicators, glass effects)
- Shared partials created (_card.html.erb, _flash_messages.html.erb, _form_input.html.erb)

### Phase 1: Simple Pages (Est: 4 hours)

**Pages:**
1. rooms/create (create-page.css)
2. sessions/new (login-page.css)
3. about/show, copyright/show (minimal custom styles)

**Per-Page Process:**
1. Identify all custom classes used in template
2. Map to Tailwind utilities or component classes
3. Replace class names in ERB template
4. Test functionality and appearance
5. Comment out old CSS file content
6. Remove `stylesheet_link_tag` from template
7. Run test suite

**Success Criteria:**
- Pages visually identical to before
- No console errors
- Forms submit correctly
- Responsive behavior preserved

### Phase 2: Medium Complexity (Est: 8 hours)

**Pages:**
1. prompts/voting (prompt-voting.css)
2. prompts/show (prompt-answer.css)
3. prompts/waiting (prompt-waiting.css)
4. prompts/results (prompt-results.css)

**Key Challenges:**
- Custom radio buttons (keep as component classes)
- Form handling with Stimulus controllers
- Scroll fade indicators
- Real-time updates via Turbo Streams

**Process:**
1. Migrate layout to Tailwind utilities
2. Keep complex component classes (answer-option, etc.)
3. Test form submissions
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
- Multi-state components (answering, voting, results, final results)
- TV mode scaling
- Complex layouts with sidebars
- QR code integration
- Background music controls

**Specific Concerns:**

**TV Mode Implementation:**
- Wrap status content in `.tv-mode` div
- Test font scaling at 1240px+
- Ensure responsive behavior below breakpoint
- Consider JavaScript detection for auto-applying class

**QR Code:**
- Keep simple flexbox layout
- Test with real QR code generation
- Ensure responsive on mobile

**Sidebar:**
- Use Tailwind flexbox: `flex flex-row gap-6`
- Turbo Stream target preserved: `id="turbo-target-sidebar"`
- Test show/hide behavior

### Phase 4: Shared Components (Est: 6 hours)

**Components:**
1. Flash messages (already created in Phase 0, but verify all usages)
2. Modals (settings-modal, blank-modal)
3. Countdown timer
4. Music player
5. Fun facts sidebar
6. Game progress sidebar

**Process:**
1. Extract to shared partials where possible
2. Use component classes for complex UI
3. Test in all contexts where component appears
4. Ensure Stimulus controllers still work

**Example: Settings Modal**

**Before (settings-modal.css):**
- 200+ lines of custom CSS
- Backdrop, modal positioning, form styling

**After:**
- Extract to `app/views/shared/_modal.html.erb` partial
- Use component class `.modal-backdrop` and `.modal-content`
- Tailwind utilities for layout within modal

### Phase 5: Cleanup (Est: 4 hours)

**Tasks:**
1. Delete all commented-out CSS files
2. Remove old `application.css` imports
3. Verify no references to old CSS files
4. Re-enable Tailwind purge in production
5. Test production build
6. Update documentation

**Files to Delete:**
- design-tokens.css
- base.css (old)
- components.css (old)
- utilities.css (old)
- All page-specific CSS files (17 files)

**Files to Keep:**
- application.css (entry point, now just imports Tailwind)
- tailwind/base.css
- tailwind/components.css
- tailwind/utilities.css

## Documentation Updates

### Update docs/CSS_CONVENTIONS.md

**Replace with Tailwind-specific conventions:**

```markdown
# CSS Conventions

This project uses **Tailwind CSS** for styling with minimal custom CSS.

## File Structure

```
app/assets/stylesheets/
├── application.css          # Main entry point
└── tailwind/
    ├── base.css             # @layer base customizations
    ├── components.css       # @layer components for complex patterns
    └── utilities.css        # @layer utilities for custom utilities

config/
└── tailwind.config.js       # Theme extensions and configuration
```

## Styling Approach

### Default: Tailwind Utilities in Templates

Use Tailwind utility classes directly in ERB templates for most styling:

```erb
<div class="flex items-center gap-4 px-6 py-4 bg-white rounded-xl shadow-md">
  <h2 class="text-2xl font-bold">Title</h2>
</div>
```

### Component Classes for Complex Patterns

Use component classes (defined in `tailwind/components.css`) for:
- Repeated complex patterns (cards, buttons, forms)
- CSS that requires pseudo-selectors (`:hover`, `:checked ~ .sibling`)
- Multi-state interactions

```erb
<button class="btn-primary">Submit</button>

<label class="answer-option">
  <input type="radio" class="answer-radio">
  <div class="answer-content">...</div>
</label>
```

### Rails Partials for Reusable Components

Extract repeated markup + styles into partials:

```erb
<%# app/views/shared/_card.html.erb %>
<div class="card-primary <%= local_assigns[:class] %>">
  <%= yield %>
</div>

<%# Usage: %>
<%= render 'shared/card', class: 'p-8' do %>
  <p>Card content</p>
<% end %>
```

## When to Use What

| Pattern | Solution | Example |
|---------|----------|---------|
| Simple layout | Tailwind utilities | `flex justify-between items-center` |
| Repeated component | Rails partial | `<%= render 'shared/card' %>` |
| Complex CSS (sibling selectors) | Component class | `.answer-option:checked ~ .answer-content` |
| One-off button | `btn-primary` class | `<button class="btn-primary">` |
| Custom color | Theme extension | `bg-brand-purple` |
| Custom animation | Tailwind config | `animate-float` |

## Tailwind Configuration

### Theme Extensions

Brand colors, custom spacing, shadows, and animations are defined in `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      brand: {
        purple: '#667eea',
        'deep-purple': '#764ba2'
      }
    },
    spacing: {
      32: '8rem'
    }
  }
}
```

### Responsive Design

Use Tailwind's responsive prefixes:

```erb
<div class="text-base md:text-lg xl:text-2xl">
  Responsive text
</div>
```

### TV Mode

For large displays (1240px+), use the `.tv-mode` class:

```erb
<div class="status-content tv-mode">
  <%# Font sizes automatically scale on large screens %>
</div>
```

## Accessibility

### Motion Safety

Use `motion-safe:` prefix for animations:

```erb
<button class="motion-safe:hover:scale-105">Hover me</button>
```

### Focus States

Ensure all interactive elements have visible focus states:

```css
@layer components {
  .btn-primary:focus {
    @apply outline-none;
    box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.3);
  }
}
```

## Best Practices

1. **Prefer utilities over custom CSS** - Use Tailwind utilities unless pattern is too complex
2. **Create partials for repetition** - Don't duplicate markup, extract to shared partials
3. **Use semantic component names** - `.btn-primary`, `.card-primary` (not `.purple-button`)
4. **Keep component CSS minimal** - Only use `@apply` when truly necessary
5. **Test responsive behavior** - Check all breakpoints (mobile, tablet, desktop, TV)
6. **Respect motion preferences** - Always use `motion-safe:` for animations
```

### Create docs/TAILWIND_MIGRATION.md

**New file documenting the migration process:**

```markdown
# Tailwind CSS Migration Guide

This document records the migration from custom CSS to Tailwind CSS.

## Migration Timeline

- **Phase 0:** Setup & Foundation ✅
- **Phase 1:** Simple Pages (create, login) ✅
- **Phase 2:** Medium Complexity (prompts) ✅
- **Phase 3:** Complex Pages (room status, TV mode) ✅
- **Phase 4:** Shared Components ✅
- **Phase 5:** Cleanup & Documentation ✅

## Before & After Examples

### Simple Layout

**Before:**
```erb
<div class="create-page">
  <div class="create-card">
    <h1 class="create-title">Title</h1>
  </div>
</div>
```

**After:**
```erb
<div class="min-h-screen flex items-center justify-center">
  <%= render 'shared/card', class: 'p-10' do %>
    <h1 class="text-4xl font-bold">Title</h1>
  <% end %>
</div>
```

### Complex Component (Radio Buttons)

**Before:**
```css
/* prompt-voting.css */
.answer-option { position: relative; }
.answer-radio { position: absolute; opacity: 0; }
.answer-radio:checked ~ .answer-content { border-color: purple; }
/* ... 50 more lines ... */
```

**After:**
```css
/* tailwind/components.css */
@layer components {
  .answer-option { @apply relative block cursor-pointer; }
  .answer-radio { @apply absolute opacity-0; }
  .answer-radio:checked ~ .answer-content { @apply border-brand-purple; }
  /* ... using @apply ... */
}
```

## Key Decisions

1. **Component classes over @apply everywhere** - Used `@apply` sparingly
2. **Rails partials for reusability** - Template partials instead of CSS abstractions
3. **Incremental migration** - One page at a time to minimize risk
4. **TV mode via component class** - `.tv-mode` class with media query overrides
5. **Disabled purge during migration** - Re-enabled after completion

## Special Cases

### TV Display Mode

Challenge: Scale all fonts 2x on screens 1240px+

Solution: `.tv-mode` class with media query overrides in components.css

### Scroll Fade Indicators

Challenge: Complex gradient backgrounds for scroll indicators

Solution: Kept as utility class `.scroll-fade-indicators` - too complex for inline

### Custom Radio Buttons

Challenge: `:checked ~ .sibling` selectors can't be done with utilities

Solution: Component classes in `@layer components` using `@apply` for common utilities

## Future Considerations

- Consider custom form builder if more forms are added
- May want to extract more reusable partials as patterns emerge
- TV mode could use JavaScript detection for automatic application
```

## Production Readiness

### Re-enable Tailwind Purge

**Update tailwind.config.js:**
```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.rb'
  ],

  // Remove safelist, enable default purging
  safelist: []
}
```

### Build for Production

```bash
# Test production build
RAILS_ENV=production bin/rails tailwindcss:build

# Verify output size
ls -lh app/assets/builds/tailwind.css

# Expected: ~25-35KB gzipped
```

## Rollback Plan

If critical issues arise during migration:

1. **Revert specific page:**
   - Uncomment old CSS file
   - Re-add `stylesheet_link_tag` to template
   - Revert ERB template changes (use git)

2. **Full rollback:**
   - Git revert all migration commits
   - Restore old `application.css` imports
   - Remove tailwind/ directory

**Note:** Incremental approach minimizes rollback risk by isolating changes per page.

## Conclusion

This specification provides a complete, actionable plan to migrate the Blanksies project to Tailwind CSS while:

- Preserving all existing functionality and design
- Improving maintainability and developer experience
- Reducing CSS bundle size and complexity
- Maintaining incremental, low-risk approach
- Addressing specific concerns (TV mode, QR code, Turbo Streams)
