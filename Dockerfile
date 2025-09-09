# syntax = docker/dockerfile:1

FROM registry.docker.com/library/ruby:3.4.5-slim@sha256:5c20b5b6c218abf1115f33e7f857863c07c79ca65d5f9dcece31c3e621ac6620 AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN set -eux ; \
    apt-get update -qq ; \
    apt-get dist-upgrade -qq ; \
    apt-get install --no-install-recommends -y curl libjemalloc2 shared-mime-info ; \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
# https://github.com/rails/rails/pull/46981
# https://github.com/rails/rails/commit/1a7e88323e6e92bf2d3ddf397b3023529b505e86#commitcomment-96003108
# We don't use this image for testing on CI, so: add "test" to BUNDLE_WITHOUT
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    BOOTSNAP_LOG="true" \
    BOOTSNAP_READONLY="true"

RUN set -eux ; \
    gem update --system "3.7.0" ; \
    gem install bundler --version "2.7.0" --force

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN set -eux ; \
    apt-get update -qq ; \
    apt-get dist-upgrade -qq ; \
    apt-get install --no-install-recommends -y build-essential git pkg-config libyaml-dev

# Install application gems
COPY Gemfile Gemfile.lock UserGemfile ./
RUN set -eux ; \
    bundle install ; \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git ; \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/ config/ Rakefile

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN set -eux ; \
    groupadd --system --gid 1000 rails ; \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash ; \
    chown -R rails:rails db log storage tmp

USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80/tcp

CMD ["./bin/thrust", "./bin/rails", "server"]
