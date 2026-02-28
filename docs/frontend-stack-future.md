# Frontend Stack Migration Plan

## Problem Statement

The current frontend stack has three CSS layers fighting each other:

1. **`errbit.css.erb`** (976 lines) — legacy stylesheet from ~2012, uses `id`-based selectors, background-image gradients, pixel-based sizing anchored to a broken `html { font-size: 62.8% }` base
2. **`app/assets/tailwind/application.css`** (1,007 lines) — hand-written CSS override sheet that brute-forces modern styling on top of layer 1 using **372 `!important` declarations**
3. **Minimal base reset** (12 lines) — replaces the deleted Eric Meyer reset

Despite importing `tailwindcss/theme` and `tailwindcss/utilities`, the Tailwind overlay uses **zero** utility classes and **zero** `@apply` directives. It's raw CSS that happens to live in the Tailwind pipeline. This creates a fragile specificity war where every change requires `!important` to win.

## Goal

Replace all three layers with a single, maintainable approach: **DaisyUI component classes in ERB templates + a small Errbit theme file**.

## Why DaisyUI

| Criteria | DaisyUI | Tailwind UI / Catalyst | Flowbite | Preflight + raw utilities |
|----------|---------|----------------------|----------|--------------------------|
| Cost | Free (MIT) | Paid ($299+) | Free tier | Free |
| Component count | 50+ semantic classes | Copy-paste HTML | Copy-paste HTML | None — build everything |
| Integration | Tailwind plugin, one line in config | Manual HTML paste | JS dependency | N/A |
| Theme system | Built-in `data-theme`, CSS variables | Manual | Manual | Manual |
| Dark mode | Free with theme swap | Manual | Plugin | Manual |
| Learning curve | Low — `btn`, `card`, `table`, `navbar` | Low but manual | Medium | High |
| Maintenance | Upgrade plugin | Re-copy HTML | Upgrade package | Maintain everything |

DaisyUI maps directly to Errbit's component vocabulary: `navbar`, `btn`, `table`, `card`, `alert`, `badge`, `tab`, `input`, `textarea`, `select`, `avatar`. The semantic class names (`btn-primary`, `alert-error`) are close to what the current CSS already targets conceptually.

## Scope

**47 ERB templates** (excluding mailer and kaminari) across 7 directories:

- `apps/` — 8 templates (index, show, edit, new, partials)
- `problems/` — 8 templates (index, show, partials)
- `users/` — 5 templates (index, show, edit, new, fields)
- `notices/` — 6 templates (partials only)
- `shared/` — 5 templates (layout partials)
- `devise/` — 3 templates (login, password reset)
- `site_config/` — 1 template
- `layouts/` — 1 template (application layout)

**2 CSS files to delete** when done:

- `app/assets/stylesheets/errbit.css.erb` (976 lines)
- `app/assets/tailwind/application.css` (1,007 lines → reduced to ~50 lines of theme config)

## Migration Phases

### Phase 0: Setup DaisyUI (1 template)

**Goal:** Install DaisyUI, configure Errbit theme, verify build pipeline works.

**Steps:**

1. Install DaisyUI v5 as a Tailwind plugin:
   ```bash
   # DaisyUI v5 is a Tailwind CSS v4 plugin — installed via CSS import
   # No npm install needed for tailwindcss-rails pipeline
   ```
   Add to `app/assets/tailwind/application.css`:
   ```css
   @import "tailwindcss";
   @plugin "daisyui";
   ```
2. Define an `errbit` DaisyUI theme with the current design tokens:
   ```css
   @plugin "daisyui" {
     themes: errbit --default {
       primary: #3b82f6;
       secondary: #64748b;
       accent: #2563eb;
       neutral: #1a1a2e;
       base-100: #f1f5f9;
       base-200: #f8fafc;
       base-300: #e2e8f0;
       info: #2563eb;
       success: #16a34a;
       warning: #d97706;
       error: #dc2626;
     }
   }
   ```
3. Convert `layouts/application.html.erb` to use DaisyUI `navbar`, container, and footer classes
4. Verify the build pipeline: `bin/dev` compiles, pages render, no regressions on login page

**Validation:** Login page looks correct, navbar renders with DaisyUI classes.

### Phase 1: Layout shell + navigation (5 templates)

**Goal:** Replace the `#header`, `#nav-bar`, `#session-links`, `#content-wrapper`, `#footer` CSS with DaisyUI classes directly in templates.

**Templates:**
- `layouts/application.html.erb`
- `shared/_navigation.html.erb`
- `shared/_session.html.erb`
- `shared/_flash_messages.html.erb`
- `shared/_link_github_account.html.erb`, `_link_google_account.html.erb`

**DaisyUI mapping:**
| Current CSS target | DaisyUI replacement |
|---|---|
| `#header` (dark gradient bar) | `navbar bg-neutral text-neutral-content` |
| `#nav-bar ul > li > a` | `btn btn-ghost` inside navbar |
| `#session-links` | navbar end section with `btn btn-ghost btn-sm` |
| `#flash-messages li.notice/success/error` | `alert alert-info/success/error` |
| `#content-wrapper` | `card bg-base-100 shadow-sm` |
| `#content-title` | `card-body` header section |
| `#action-bar` | `btn-group` or inline `btn btn-sm` |
| `#footer` | `footer footer-center` |

**CSS removed after this phase:** ~200 lines from the overlay (header, nav, session links, flash, footer, content-wrapper, content-title, action-bar sections).

**Validation:** Navigate all pages. Header, nav, flash messages, footer look correct.

### Phase 2: Tables + data display (8 templates)

**Goal:** Replace hand-styled tables with DaisyUI `table` component.

**Templates:**
- `apps/_table.html.erb`
- `problems/_table.html.erb`
- `problems/_tally_table.html.erb`
- `problems/_sparkline.html.erb`
- `users/index.html.erb`
- `notices/_summary.html.erb`
- `site_config/index.html.erb`

**DaisyUI mapping:**
| Current CSS target | DaisyUI replacement |
|---|---|
| `table` (base) | `table table-zebra` |
| `table thead th` | Inherits from DaisyUI table theme |
| `table.apps/errs tbody tr:hover` | `hover` class on table |
| `.count a` (badge) | `badge badge-sm` |
| `.count a.resolved` | `badge badge-success badge-sm` |
| `td.resolve a` | `btn btn-ghost btn-xs` |
| `.environment` span | `badge badge-ghost badge-xs` |
| `.inline_comment` | `badge badge-info` |

**CSS removed:** ~150 lines (all table, count badge, resolve, environment, inline comment, tally sections).

**Validation:** Apps index, problems index, users index, site config — tables render with zebra striping, badges look correct.

### Phase 3: Forms + inputs (12 templates)

**Goal:** Replace hand-styled form elements with DaisyUI `input`, `select`, `textarea`, `label`, `fieldset`, `btn` classes.

**Templates:**
- `apps/_fields.html.erb`
- `apps/_issue_tracker_fields.html.erb`
- `apps/_service_notification_fields.html.erb`
- `apps/edit.html.erb`, `apps/new.html.erb`
- `users/_fields.html.erb`
- `users/edit.html.erb`, `users/new.html.erb`
- `devise/sessions/new.html.erb`
- `devise/passwords/new.html.erb`, `devise/passwords/edit.html.erb`
- `shared/_notice_fingerprinter.html.erb`

**DaisyUI mapping:**
| Current CSS target | DaisyUI replacement |
|---|---|
| `form input[type="text/password/email"]` | `input input-bordered w-full` |
| `form textarea` | `textarea textarea-bordered w-full` |
| `form select` | `select select-bordered w-full` |
| `form label` | `label` (DaisyUI label component) |
| `form fieldset` | `fieldset` with `bg-base-200 rounded-xl p-5` |
| `form fieldset legend` | `legend text-xs font-semibold uppercase` |
| `.button`, `input[type="submit"]` | `btn` / `btn btn-primary` |
| `form div.buttons` | `flex gap-2` wrapper |
| `form .error-messages` | `alert alert-error` |
| `form .required label::after` | Custom `after:` utility or keep as-is |
| Search input with icon | `input` with `join` prefix icon pattern |

**CSS removed:** ~250 lines (all button, form input, textarea, select, fieldset, label, search, error-messages sections).

**Validation:** Create/edit app, create/edit user, login, password reset — all forms submit correctly, validation errors display.

### Phase 4: Problem detail + comments (8 templates)

**Goal:** Replace problem show page components with DaisyUI classes.

**Templates:**
- `problems/show.html.erb`
- `problems/_issue_tracker_links.html.erb`
- `notices/_backtrace.html.erb`, `notices/_backtrace_line.html.erb`
- `notices/_environment.html.erb`, `notices/_params.html.erb`
- `notices/_session.html.erb`, `notices/_user_attributes.html.erb`

**DaisyUI mapping:**
| Current CSS target | DaisyUI replacement |
|---|---|
| `.tab-bar` | `tabs tabs-bordered` |
| `.tab-bar a.button` | `tab` |
| `.tab-bar a.button.active` | `tab tab-active` |
| `.window` (backtrace container) | `mockup-code` or `card bg-neutral` |
| `table.backtrace` | Keep custom (monospace code display) |
| `#content-comments` | `card-body` section |
| `table.comment` | `chat` component or `card card-bordered` |
| `table.comment img.gravatar` | `avatar` component |
| `.raw_data` | `collapse` or `mockup-code` |
| `.notice-pagination` | `join` with `btn btn-sm` |

**CSS removed:** ~100 lines (tab bar, backtrace, comments, raw data, pagination sections).

**Validation:** Problem show page — tabs switch, backtrace renders, comments display, notice pagination works.

### Phase 5: Remaining pages + cleanup (5 templates)

**Goal:** Convert remaining pages, then delete legacy CSS files.

**Templates:**
- `apps/show.html.erb`
- `apps/_configuration_instructions.html.erb`, `_configuration_instructions_wrapper.html.erb`
- `apps/_search.html.erb`
- `problems/_search.html.erb`

**Final cleanup steps:**

1. Delete `app/assets/stylesheets/errbit.css.erb`
2. Remove `*= require errbit` from `app/assets/stylesheets/application.css`
3. Reduce `app/assets/tailwind/application.css` to:
   - Tailwind + DaisyUI imports
   - Errbit theme definition
   - Minimal base reset (the 12-line `*, ul, img` block)
   - Any truly Errbit-specific overrides that DaisyUI doesn't cover (estimate: <50 lines)
4. Remove `-moz-` and `-webkit-` vendor prefixes (Tailwind handles autoprefixing)
5. Remove all `!important` declarations (no specificity war without errbit.css.erb)
6. Fix the `html { font-size: 62.8% }` issue at the source — once errbit.css.erb is gone, the `100% !important` override is no longer needed

**Validation:** Full visual regression check of all pages. Run `bundle exec rspec spec/feature/` to verify browser tests pass.

## What Stays the Same

- **Font Awesome 7** — icons via importmaps, `fa_icon` helper, `dom.watch()`. No change.
- **JavaScript stack** — jQuery/UJS/PJAX (Sprockets) + Stimulus (importmaps). No change.
- **Mailer CSS** — `mailers/mailer.css` with `actionmailer_inline_css`. No change.
- **Kaminari templates** — pagination partials. Minimal class name updates.
- **Build pipeline** — `tailwindcss-rails` gem, `bin/dev` for development. No change.

## Result

| Metric | Before | After |
|--------|--------|-------|
| CSS files | 3 (reset + errbit.css.erb + tailwind overlay) | 1 (tailwind/application.css) |
| Total CSS lines | ~2,000 | ~50 (theme + overrides) |
| `!important` count | 372 | 0 |
| Styling approach | ID-based selectors overriding each other | Utility/component classes in templates |
| Theme changes | Edit 1,000 lines of CSS | Change 10 theme variables |
| Dark mode | Not possible | Swap `data-theme` attribute |

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| DaisyUI component doesn't match Errbit's layout exactly | Use Tailwind utility classes to customize; DaisyUI components are just base styles |
| Visual regression during migration | Migrate one phase at a time; each phase is independently deployable |
| Plugin gems (`errbit_*`) inject CSS that expects old selectors | Check for `errbit_*` gems in UserGemfile; most only inject issue tracker logic, not CSS |
| Kaminari pagination templates need updates | Update `app/views/kaminari/` partials to use DaisyUI `join` + `btn` |
| `form.js` JavaScript relies on CSS classes | Audit `form.js` for class-based selectors; update if needed |

## Phase Dependencies

```
Phase 0 (setup)
  └── Phase 1 (layout shell)
        ├── Phase 2 (tables) — independent of Phase 3/4
        ├── Phase 3 (forms) — independent of Phase 2/4
        └── Phase 4 (problem detail) — independent of Phase 2/3
              └── Phase 5 (cleanup) — depends on all above
```

Phases 2, 3, and 4 can be done in parallel or any order after Phase 1.
