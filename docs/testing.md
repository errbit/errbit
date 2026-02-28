# Testing Guide

Errbit uses RSpec with MongoDB. Tests run in random order with documentation format output.

## Running Tests

```bash
bundle exec rspec                                    # full suite
bundle exec rspec spec/models/problem_spec.rb        # single file
bundle exec rspec spec/models/problem_spec.rb:42     # single example
bundle exec rspec spec/feature/                      # directory
bundle exec rspec --only-failures                    # re-run failures
HEADLESS=false bundle exec rspec spec/feature/       # visible Chrome
```

## Suite Layout

| Directory | What it tests |
|-----------|--------------|
| `spec/models/` | Mongoid models — fields, validations, scopes, methods |
| `spec/controllers/` | Authorization, routing, response handling |
| `spec/feature/` | Browser-driven happy-path UI flows (Capybara + Selenium) |
| `spec/system/` | Browser-driven auth flows (sign in/out, OAuth) |
| `spec/requests/` | API endpoints and notice intake |
| `spec/views/` | View template rendering |
| `spec/decorators/` | Draper presenters |
| `spec/interactors/` | Service objects |
| `spec/policies/` | Pundit authorization |
| `spec/jobs/` | Background jobs |
| `spec/factories/` | FactoryBot definitions |
| `spec/support/` | Shared config, helpers, macros |

## Key Concepts

**Database isolation** — MongoDB collections are truncated before every test. Each example starts with a clean database. No DatabaseCleaner needed.

**Authentication** — Use `sign_in(user)` (Devise helper) in most specs. Available for controller, system, feature, and request specs.

**Factories** — Use `create(:user)`, `create(:app)`, `create(:notice)`, etc. FactoryBot methods are available globally. Creating a `:notice` auto-builds the full App -> Problem -> Err -> Backtrace chain.

**HTTP mocking** — All outbound HTTP is disabled (WebMock). Use VCR cassettes or WebMock stubs for external APIs.

**Browser specs** — Feature and system specs run in headless Chrome with `retry: 3` for flakiness. Use `HEADLESS=false` to see the browser.

## Writing a New Test

Require `"rails_helper"`, set the appropriate `type:`, use FactoryBot for data, and reference UI text via `I18n.t(...)`.

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User creates an app", type: :feature, retry: 3 do
  let!(:admin) { create(:user, admin: true) }

  before { sign_in(admin) }

  it "creates a new app" do
    visit new_app_path
    fill_in "Name", with: "My App"
    click_button I18n.t("apps.new.add_app")
    expect(page).to have_content(I18n.t("controllers.apps.flash.create.success"))
  end
end
```

## CI

GitHub Actions runs `bundle exec rspec` on every push/PR to `main` against MongoDB 7.0, 8.0, and 8.2. See `.github/workflows/rspec.yml`.

## Further Reading

See [testing-advanced.md](testing-advanced.md) for detailed documentation on support files, factory definitions, Capybara/Chrome configuration, coverage setup, HTTP mocking, macros, and troubleshooting.
