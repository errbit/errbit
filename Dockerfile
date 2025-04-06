# syntax = docker/dockerfile:1

FROM registry.docker.com/library/ruby:3.4.2-slim AS base

# Rails app lives here
WORKDIR /rails

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
    gem update --system "3.6.6" ; \
    gem install bundler --version "2.6.6" --force

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN set -eux ; \
    apt-get update -qq ; \
    apt-get dist-upgrade -qq ; \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config shared-mime-info

# Install application gems
COPY Gemfile Gemfile.lock UserGemfile ./
RUN set -eux ; \
    bundle install ; \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git ; \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN set -eux ; \
    apt-get update -qq ; \
    apt-get install --no-install-recommends -y curl ; \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN set -eux ; \
    useradd rails --create-home --shell /bin/bash ; \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000

CMD ["./bin/rails", "server"]
