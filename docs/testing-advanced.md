# Testing — Advanced Reference

For an overview of running tests, suite layout, key concepts, and writing new tests, see [testing.md](testing.md).

This document covers the detailed internals: configuration files, support infrastructure, factory definitions, browser setup, HTTP mocking, coverage, and troubleshooting.

## Configuration

### RSpec Options (`.rspec`)

```
--require spec_helper
--order random
--format documentation
```

### spec_helper.rb

- Sets `RAILS_ENV` to `"test"`
- Configures SimpleCov with **branch coverage** as the primary metric
- Adds coverage groups for Decorators, Interactors, and Policies
- Auto-requires all files under `spec/support/`
- Enables `--only-failures` via `example_status_persistence_file_path`
- Uses zero-monkey-patching mode (`disable_monkey_patching!`)

### rails_helper.rb

Stub file (frozen string literal only). All setup lives in `spec_helper.rb`. Either `require "rails_helper"` or `require "spec_helper"` works.

## Support Files

All files in `spec/support/` are auto-loaded:

| File | Purpose |
|------|---------|
| `action_mailer.rb` | Sets mailer delivery to `:test` mode |
| `active_job.rb` | Runs jobs inline (synchronously) during tests |
| `active_support.rb` | Includes `TimeHelpers` (`travel_to`, `freeze_time`) globally |
| `capybara.rb` | Registers custom `:selenium_chrome_headless` driver with `--headless=new` |
| `devise.rb` | Includes Devise test helpers scoped by spec type |
| `factory_bot_rails.rb` | Includes FactoryBot DSL methods (`create`, `build`, etc.) globally |
| `feature_helper.rb` | Provides `create_app_with_problem` helper for feature specs |
| `macros.rb` | Defines `it_requires_authentication` and `it_requires_admin_privileges` macros |
| `mongoid.rb` | Truncates all collections before each test (database isolation) |
| `mongoid-rspec.rb` | Includes Mongoid matchers (`have_field`, `be_embedded_in`) for model specs |
| `omniauth.rb` | Enables OmniAuth test mode (bypasses real OAuth flows) |
| `rspec-rebound.rb` | Configures retry behavior and Capybara reset between retries |
| `selenium-webdriver.rb` | Sets Capybara driver for system and feature specs |
| `super_diff.rb` | Loads improved diff output for test failures |
| `vcr.rb` | Configures VCR cassette storage, WebMock hook, and strict mode |
| `webmock.rb` | Disables all outbound HTTP connections in tests |

## Database Isolation

MongoDB does not support transactional rollback. Instead, every collection is truncated before each test:

```ruby
# spec/support/mongoid.rb
RSpec.configure do |config|
  config.before(:suite) do
    Mongoid::Config.truncate!
    Mongoid::Tasks::Database.create_indexes
  end

  config.before do
    Mongoid::Config.truncate!
  end
end
```

- `before(:suite)` — truncates once and creates indexes at the start of the run
- `before(:each)` — truncates before every individual example

No DatabaseCleaner needed.

## Authentication Helpers

Devise helpers are included per spec type in `spec/support/devise.rb`:

| Spec Type | Helper Module |
|-----------|--------------|
| `:controller` | `Devise::Test::ControllerHelpers` |
| `:system` | `Devise::Test::IntegrationHelpers` |
| `:feature` | `Devise::Test::IntegrationHelpers` |
| `:request` | `Devise::Test::IntegrationHelpers` |

To exercise the login form directly:

```ruby
visit root_path
fill_in "Email", with: user.email
fill_in "Password", with: "password"
click_button I18n.t("devise.sessions.new.sign_in")
```

## Controller Macros

Defined in `spec/support/macros.rb` as top-level methods (not a module):

```ruby
it_requires_authentication
it_requires_admin_privileges
```

These generate shared examples verifying redirect behavior for unauthenticated or non-admin users across all standard CRUD actions. Both accept an `options` hash with `:for` (action-to-verb map) and `:params` overrides.

## Factory Definitions

### Core Factories

| Factory | Key Attributes | Notes |
|---------|---------------|-------|
| `:user` | `email`, `name`, `password` | Uses Faker with `.unique` |
| `:app` | `name` (sequenced), `repository_branch` | |
| `:app_with_watcher` | Parent: `:app` | Builds a watcher after build |
| `:problem` | `app`, `error_class`, `environment` | |
| `:problem_resolved` | Parent: `:problem` | Creates err + notice, then resolves |
| `:problem_with_errs` | Parent: `:problem` | Creates 3 errs |
| `:problem_with_comments` | Parent: `:problem` | Creates 3 comments |
| `:err` | `problem`, `fingerprint` | |
| `:notice` | `app`, `err`, `error_class`, `message`, `backtrace` | Calls `Problem.cache_notice` after create |
| `:backtrace` | `lines` (99 random frames) | |
| `:comment` | `user`, `body` | |
| `:watcher` | `app`, `watcher_type`, `email` | |
| `:user_watcher` | Parent: `:watcher` | Has an associated user |
| `:issue_tracker` | `app`, `type_tracker` | Uses mock tracker |
| `:notification_service` | `app`, `room_id`, `api_token` | Multiple subclass factories available |

### Notification Service Subclass Factories

`:gtalk_notification_service`, `:slack_notification_service`, `:campfire_notification_service`, `:hoiio_notification_service`, `:hubot_notification_service`, `:pushover_notification_service`, `:webhook_notification_service`

### Usage Examples

```ruby
# Full object graph via notice
notice = create(:notice)  # auto-creates app, err, problem, backtrace

# Feature helper (available in type: :feature specs)
data = create_app_with_problem(name: "My App")
data[:app]      # the App
data[:problem]  # the Problem
data[:err]      # the Err
data[:notice]   # the Notice

# Resolved problem
create(:problem_resolved)
```

## Spec Type Details

### Model Specs

Mongoid matchers from `mongoid-rspec` (included for `type: :model`):

```ruby
it { is_expected.to have_field(:name).of_type(String) }
it { is_expected.to have_many(:problems) }
it { is_expected.to embed_many(:watchers) }
it { is_expected.to validate_presence_of(:name) }
it { is_expected.to have_index_for(api_key: 1) }
```

### Policy Specs

Use `pundit-matchers`:

```ruby
it { is_expected.to permit_action(:show) }
it { is_expected.to forbid_action(:destroy) }
```

### Adding a New Factory

```ruby
# spec/factories/widget_factory.rb
FactoryBot.define do
  factory :widget do
    sequence(:name) { |n| "Widget ##{n}" }
    active { true }
    app
  end
end
```

### Adding a New Model Spec

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Widget, type: :model do
  it { is_expected.to have_field(:name).of_type(String) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:app) }

  describe "#activate!" do
    it "sets active to true" do
      widget = create(:widget, active: false)
      widget.activate!
      expect(widget.active).to be true
    end
  end
end
```

## Browser Test Configuration

### Chrome Driver Options

The custom Capybara driver (`spec/support/capybara.rb`) configures:
- `--headless=new` (Chrome's newer headless mode)
- `--disable-gpu` on Windows
- `--disable-site-isolation-trials` (ChromeDriver workaround)
- Password manager leak detection disabled

### Retry on Flakiness

Browser tests use `retry: 3` metadata with `rspec-rebound`. On retry, the Capybara session is reset via the callback in `spec/support/rspec-rebound.rb`. Retry output is verbose — each attempt and its error are shown.

## HTTP Mocking

### WebMock

All outbound HTTP connections are disabled (`WebMock.disable_net_connect!`). Localhost is allowed via VCR's `ignore_localhost = true`.

Un-stubbed external requests raise:

```
WebMock::NetConnectNotAllowedError:
  Real HTTP connections are disabled.
```

### VCR

Cassettes stored at `spec/cassettes/`. Configured in strict mode — unused recorded interactions cause failures.

```ruby
it "fetches data", vcr: { cassette_name: "api_response" } do
  # First run records; subsequent runs replay
end
```

## Coverage

SimpleCov generates reports at `coverage/index.html` with **branch coverage** as primary metric. Custom groups:

| Group | Path |
|-------|------|
| Controllers | `app/controllers` |
| Models | `app/models` |
| Decorators | `app/decorators` |
| Interactors | `app/interactors` |
| Policies | `app/policies` |
| Helpers | `app/helpers` |
| Mailers | `app/mailers` |
| Jobs | `app/jobs` |

## CI Details

Tests run via `.github/workflows/rspec.yml`:

- **Ruby**: 4.0.1
- **MongoDB matrix**: 7.0, 8.0, 8.2 (3 parallel jobs)
- **Timeout**: 10 minutes per job
- **Steps**: bootsnap precompile, Zeitwerk check, asset precompile, `errbit:bootstrap`, `bundle exec rspec`
- `fail-fast: false` — all matrix combinations run even if one fails

## Troubleshooting

### `WebMock::NetConnectNotAllowedError`

An external HTTP request is being made without a stub or VCR cassette. Either:
- Stub with WebMock: `stub_request(:get, "https://api.example.com/data").to_return(body: "{}")`
- Record with VCR: add `vcr: { cassette_name: "my_cassette" }` metadata

### Browser tests fail intermittently

- Ensure `retry: 3` is set on the spec
- Use Capybara's waiting matchers (`have_content`, `have_selector`) instead of `sleep`
- Debug visually: `HEADLESS=false bundle exec rspec spec/feature/my_spec.rb`

### "Password can't be blank" when editing users

The user edit form includes password fields. Devise validates them on submit. Either fill in the password fields or use a user with `github_login` set (which skips password validation).

### Mongoid index warnings

Run `bundle exec rails errbit:bootstrap` to create indexes. CI does this automatically.

### Reproducing a specific random order

```bash
bundle exec rspec --seed 12345
```
