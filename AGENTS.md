# Errbit — agent guide

## Project status: MongoDB → SQL port in progress

Errbit is being ported from MongoDB/Mongoid to SQL/ActiveRecord on branch `claude-code-port-to-sql`.

- **Old Mongoid models** live at `app/models/*.rb` (e.g. `app/models/user.rb` → `User`). They stay in place.
- **New AR models** live under the `Errbit::` namespace at `app/models/errbit/*.rb` (e.g. `app/models/errbit/user.rb` → `Errbit::User`).
- Both ORMs coexist during the port. Devise is wired only to `Errbit::User` (AR); the Mongoid `User` keeps its legacy fields as plain data for the migration rake task but is no longer a Devise model.

## Conventions for ported models

- Tables use the `errbit_` prefix via `Errbit.table_name_prefix` in `app/models/errbit.rb`.
- AR models inherit from `Errbit::ApplicationRecord` (uses `primary_abstract_class`).
- **Every ported table gets a `bson_id` string column with a unique index.** This stores the original Mongo BSON id so a future ETL step can link records back to their Mongo origin. Don't skip it.
- Foreign keys use the `errbit_` prefix: `errbit_app_id`, `errbit_user_id`, etc.
- Test infra: `database_rewinder` for cleanup (`spec/support/active_record.rb`), `shoulda-matchers` available for validation matchers.
- Factories live under `spec/factories/errbit/`, specs under `spec/models/errbit/`. Factory names are prefixed (e.g. `:errbit_user`, `:errbit_app`, `:errbit_watcher`).

## Porting a new model

When asked to port the next Mongoid model:

1. Add a migration `db/migrate/<timestamp>_create_errbit_<plural>.rb` — include `bson_id` + unique index, foreign keys with `errbit_` prefix, all data fields from the Mongoid model.
2. Create `app/models/errbit/<name>.rb` — port fields/validations/callbacks/methods. Skip methods that depend on still-unported models; leave them for when the dependency is ported.
3. If a previously-ported model has an association to this one, wire it up now (e.g. when porting `Watcher`, add `has_many :watchers` to `Errbit::App`).
4. Add `spec/factories/errbit/<name>_factory.rb` and `spec/models/errbit/<name>_spec.rb`.
5. Run migrations in both envs and run the spec.
6. **Don't delete the old Mongoid model** — both must work until the full port is done.

## Commands

```sh
bundle exec rails db:migrate                  # development
RAILS_ENV=test bundle exec rails db:migrate   # test

bundle exec rspec                                       # full suite
bundle exec rspec spec/models/errbit/                   # all ported AR models
bundle exec rspec spec/models/errbit/<name>_spec.rb     # one spec
```

Tests require a running MongoDB (the Mongoid models are still loaded on boot). The user runs mongo via Docker.

## Things to check before running tests

- `bundle install` after Gemfile changes.
- Run migrations in **both** `development` and `test` envs — they're separate sqlite files (`storage/development.sqlite3`, `storage/test.sqlite3`).
- After porting, run the namespaced spec **and** the old Mongoid spec to confirm no regression.
