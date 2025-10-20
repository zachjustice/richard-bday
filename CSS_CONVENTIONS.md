# CSS Naming Conventions

This document outlines the CSS naming conventions used in this project. We follow a **BEM-inspired** approach with some Rails-specific adaptations.

## BEM Overview

BEM stands for **Block Element Modifier**:
- **Block**: Standalone component (e.g., `status-header`)
- **Element**: Part of a block (e.g., `status-header__logo`)
- **Modifier**: Variant of a block or element (e.g., `button--primary`)

## Our Conventions

### 1. Block Naming

Blocks are named with **kebab-case** and represent independent components:

```css
.status-header { }
.waiting-room-card { }
.create-page { }
.game-status-badge { }
```

**Pattern**: `{component-name}`

### 2. Element Naming

We use **separate classes** instead of BEM's double underscore for better readability:

```css
/* Instead of: .status-header__logo */
.header-left { }
.header-center { }
.header-right { }
.app-logo { }
.logo-emoji { }
```

**Pattern**: `{descriptive-name}` (semantically nested within parent block)

**Why**: Rails conventions favor simpler class names, and our components are well-scoped

### 3. Modifier Naming

For variants, we use a single dash with descriptive names:

```css
.button { }
.button-primary { }
.button-secondary { }
```

**Pattern**: `{block}-{variant}`

### 4. State Classes

For dynamic states, use prefixes:

```css
.is-active { }
.is-hidden { }
.is-loading { }
.has-error { }
```

**Pattern**: `is-{state}` or `has-{state}`

### 5. Utility Classes

Single-purpose utilities follow a functional approach:

```css
.flex { }
.flex-col { }
.gap-4 { }
.text-center { }
.rounded-lg { }
```

**Pattern**: `{property}-{value}` or `{property}`

## Component Structure

### Page-Level Components

Page components are named after their route:

```css
/* /rooms/create */
.create-page { }
.create-card { }
.create-title { }

/* /rooms/:id/status */
.status-header { }
.status-content { }
.status-footer { }
```

**Pattern**: `{page-name}-{element}`

### Feature Components

Feature components are named after their purpose:

```css
.waiting-room-container { }
.waiting-room-card { }
.waiting-room-grid { }

.stories-section { }
.users-section { }
```

**Pattern**: `{feature-name}-{element}`

### Generic Components

Reusable components use generic names:

```css
.players-list { }
.player-item { }
.game-status-badge { }
.room-code-container { }
```

**Pattern**: `{component-type}-{element}`

## Nesting Guidelines

### Avoid Deep Nesting

❌ **Don't**:
```css
.status-header .header-center .game-status-badge .status-icon { }
```

✅ **Do**:
```css
.status-icon { }
```

### Scope When Necessary

Use parent selectors only when needed for specificity:

```css
.status-content .error-notice { }
```

## File Organization

### Structure

```
app/assets/stylesheets/
├── design-tokens.css    # CSS custom properties (colors, spacing, etc.)
├── base.css            # Reset, typography, base HTML elements
├── components.css      # Semantic components (buttons, forms, nav)
├── utilities.css       # Single-purpose utility classes (layout, spacing)
├── create-page.css     # /rooms/create page-specific styles
└── status-page.css     # /rooms/:id/status page-specific styles
```

### File Responsibilities

**design-tokens.css**: Design system values
- Color palette
- Spacing scale
- Typography scale
- Border radius
- Shadows
- Z-index layers
- Transitions

**base.css**: Base HTML styling
- CSS reset
- Typography (h1-h6, p, a)
- Body and html defaults

**components.css**: Semantic components
- Buttons (button, input[type="submit"])
- Form elements (input, select, textarea)
- Radio groups
- Navigation (nav, nav a)

**utilities.css**: Layout and spacing utilities
- Flexbox utilities (.flex, .flex-col, .items-center, .justify-*)
- Spacing utilities (.gap-*, .p-*, .m-*, .mt-*, .mb-*)
- Width utilities (.w-full, .max-w-*)
- Text utilities (.text-center, .font-*, .text-*)
- Color utilities (.text-*, .bg-*)
- Border utilities (.rounded-*)
- Shadow utilities (.shadow-*)
- Container and grid (.container, .row, .col-*)

**Page-specific files**: Unique page styles
- Component styles specific to that page
- No utilities or shared components

### Import Order

```css
@import url("design-tokens.css");  /* 1. Design system */
@import url("base.css");           /* 2. Base styles */
@import url("components.css");     /* 3. Components */
@import url("utilities.css");      /* 4. Utilities */
```

## Design Tokens

All design values use CSS custom properties:

```css
/* Colors */
color: var(--color-primary-purple);
background: var(--bg-secondary);

/* Spacing */
padding: var(--space-4);
gap: var(--space-2);

/* Typography */
font-size: var(--font-size-xl);
font-weight: var(--font-weight-semibold);

/* Borders */
border-radius: var(--radius-lg);

/* Shadows */
box-shadow: var(--shadow-md);
```

## Examples

### Good Examples

```html
<!-- Status Header -->
<header class="status-header">
  <div class="header-left">
    <div class="app-logo">
      <span class="logo-emoji">📝✨</span>
      <span class="app-name">Blanksies</span>
    </div>
  </div>
</header>

<!-- Waiting Room Card -->
<div class="waiting-room-card">
  <ul class="players-list">
    <li class="player-item">Player 1</li>
  </ul>
</div>
```

### Bad Examples

```html
<!-- ❌ Too generic -->
<div class="container">
  <div class="item">
    <span class="text">Content</span>
  </div>
</div>

<!-- ❌ Overly specific -->
<div class="status-page-header-left-side-logo-container">
  ...
</div>

<!-- ❌ Inline styles -->
<div style="padding: 20px; color: red;">
  ...
</div>
```

## Best Practices

1. **Use semantic names** - Name based on purpose, not appearance
   - ✅ `.player-item`
   - ❌ `.blue-box`

2. **Keep specificity low** - Avoid nesting and IDs
   - ✅ `.status-header`
   - ❌ `header#status .header-center > div`

3. **Use design tokens** - Never hardcode values
   - ✅ `color: var(--color-primary-purple)`
   - ❌ `color: #667eea`

4. **Prefer utilities** - Use utility classes for one-offs
   - ✅ `<div class="flex gap-4 items-center">`
   - ❌ Creating a new class for simple layouts

5. **Component scoping** - Keep related styles together
   - Group all `.status-header-*` classes in same section

## When to Create New Classes

### Create a new class when:
- The pattern is used 3+ times
- The component has distinct behavior/styling
- It represents a logical UI component

### Use utilities when:
- One-off styling needs
- Simple layout adjustments
- Spacing tweaks
- Quick prototyping

## Migration Path

When refactoring existing code:

1. Identify the component/block
2. Group related elements
3. Replace hardcoded values with design tokens
4. Use utilities for simple patterns
5. Extract repeated logic to helpers
6. Test for visual regressions

## Resources

- [BEM Methodology](http://getbem.com/)
- [CSS Guidelines](https://cssguidelin.es/)
- [Maintainable CSS](https://maintainablecss.com/)
