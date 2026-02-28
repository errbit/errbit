# Frontend Stack

Errbit uses the Rails asset pipeline (Sprockets) for all stylesheets and JavaScript.

## CSS

### Asset Pipeline (`app/assets/stylesheets/application.css`)

Stylesheets loaded via Sprockets manifest in this order:

1. **errbit** — Legacy application stylesheet (`errbit.css.erb`, ~980 lines). Defines the original UI layout, colors, and components. Uses ERB for asset path helpers.
2. **modern** — Modern UI overlay (`modern.css`, ~990 lines). Loaded after errbit and overrides it via CSS source order. Defines design tokens as CSS custom properties and reskins the entire interface.

### Modern UI Overlay (`app/assets/stylesheets/modern.css`)

A plain CSS stylesheet that layers a modern look on top of `errbit.css.erb`. This file:

- Defines Errbit design tokens as `:root` CSS custom properties (colors, spacing)
- Includes a minimal base reset (box-sizing, list-style, vertical-align)
- Overrides the legacy styles by targeting existing HTML IDs/classes
- Uses explicit `px` values throughout to avoid issues with the legacy `html { font-size: 62.8% }` base

**Rollback:** Remove `*= require modern` from `application.css` to revert to the legacy UI.

### Font Awesome (SVG+JS via Importmaps)

Icons use Font Awesome 7 Free with the SVG+JS rendering approach, loaded via Rails importmaps.

- **Packages:** Three modular ESM packages pinned in `config/importmap.rb` and vendored in `vendor/javascript/`:
  - `@fortawesome/fontawesome-svg-core` — core SVG rendering engine
  - `@fortawesome/free-solid-svg-icons` — solid icon definitions
  - `@fortawesome/free-brands-svg-icons` — brand icon definitions
- **Initializer:** `app/javascript/fontawesome.js` — imports all solid and brand icons into the library, then calls `dom.watch()` to convert `<i>` tags to inline `<svg>` elements at runtime (also handles dynamic DOM mutations from PJAX)
- **Loaded** via `import "fontawesome"` in `app/javascript/application.js`
- **Icon helpers** in `ApplicationHelper`:
  - `fa_icon(name, prefix: "fa-solid", **options)` — generates `<i>` tags in ERB that FA's `dom.watch()` converts to SVGs client-side. Usage: `fa_icon("briefcase")`, `fa_icon("github", prefix: "fa-brands")`, `fa_icon("trash", class: "extra")`
  - `fa_icon_class(label)` — maps service/tracker labels (e.g. `"github"`, `"slack"`) to FA class strings (e.g. `"fa-brands fa-github"`)

No webfonts, no npm CSS dependency, no symlinks. Icons render as inline SVGs with no `.woff2` network requests.

### Mailer CSS

- `app/assets/stylesheets/mailers/mailer.css` — Separate stylesheet for email templates
- Emails use the `actionmailer_inline_css` gem to inline styles for email client compatibility
- Layout: `app/views/layouts/mailer.html.erb`

### Design Characteristics

- Responsive layout (max-width 1140px, centered)
- Dark slate gradient header with flexbox navigation
- System font stack (-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, ...)
- Flat buttons with subtle shadows, rounded corners (8px)
- Form inputs: 44px min-height, 15px font, blue focus ring
- Semantic flash message colors (blue notice, green success, red error, amber warning)

## JavaScript

### Sprockets Bundle (`app/assets/javascripts/app.js.erb`)

Legacy JS loaded via Sprockets in this order:

1. **jQuery** (v4.x) — via `jquery-rails` gem. Core DOM manipulation.
2. **jQuery UJS** — Rails unobtrusive JS (CSRF tokens, remote forms, confirmation dialogs)
3. **Underscore.js** — via `underscore-rails` gem. Utility functions.
4. **form.js** — Custom form enhancements: nested forms (add/remove watchers, etc.), dynamic field generation for issue trackers and notification services, checkbox-driven visibility toggles.
5. **PJAX** — via `pjax_rails` gem. AJAX-based page transitions for notice pagination.
6. **errbit.js** — Core application behavior.

The manifest also auto-requires assets from any gem matching `errbit_*` (plugin system).

### Import Maps + Stimulus (`config/importmap.rb`)

Modern JS loaded alongside the legacy Sprockets bundle:

- **Stimulus** (`@hotwired/stimulus`) — Rails component framework
- **@stimulus-components/reveal** (v5.0.0) — Toggle element visibility
- Controllers live in `app/javascript/controllers/` (currently minimal: `application.js`, `index.js`)

Both systems coexist: Sprockets handles legacy jQuery code, Import Maps handle modern Stimulus controllers.

## Key Frontend Gems

| Gem | Purpose |
|-----|---------|
| `jquery-rails` | jQuery + jQuery UJS |
| `underscore-rails` | Underscore.js utility library |
| `pjax_rails` | AJAX page navigation |
| `@fortawesome/fontawesome-svg-core` | FA SVG rendering engine (v7.x, vendored via importmap) |
| `stimulus-rails` | Stimulus JS framework |
| `importmap-rails` | ES module imports without bundler |
| `sprockets-rails` | Asset pipeline |
| `actionmailer_inline_css` | Inline CSS in emails |
| `kaminari` | Pagination UI |
| `draper` | View decorator/presenter pattern |

## No External Bundler

There is no Webpack, esbuild, Vite, or Tailwind build pipeline. All CSS is served directly through Sprockets. Font Awesome is vendored via importmaps (no npm dependency). JavaScript is served via Sprockets (legacy) and Import Maps (modern).
