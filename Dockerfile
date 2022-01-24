FROM ruby:2.7.5-alpine
LABEL maintainer="David Papp <david@ghostmonitor.com>"

ENV BUNDLER_VERSION=2.3.5
ENV RUBYGEMS_VERSION=3.3.5

WORKDIR /app

# throw errors if Gemfile has been modified since Gemfile.lock
RUN echo "gem: --no-document" >> /etc/gemrc \
  && bundle config --global frozen 1 \
  && bundle config --global disable_shared_gems false \
  && gem update --system $RUBYGEMS_VERSION \
  && gem install bundler --version $BUNDLER_VERSION \
  && apk add --no-cache \
    curl \
    less \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    tzdata

COPY ["Gemfile", "Gemfile.lock", "/app/"]

RUN apk add --no-cache --virtual build-dependencies build-base \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle config set without 'test development no_docker' \
  && bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry 5 \
  && bundle clean --force \
  && apk del build-dependencies

COPY . /app

RUN RAILS_ENV=production bundle exec rake assets:precompile \
  && rm -rf /app/tmp/* \
  && chmod 777 /app/tmp

EXPOSE 8080

HEALTHCHECK CMD curl --fail "http://$(/bin/hostname -i | /usr/bin/awk '{ print $1 }'):${PORT:-8080}/users/sign_in" || exit 1

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]

