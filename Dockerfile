FROM ruby:2.3.3-alpine
MAINTAINER David Papp <david@ghostmonitor.com>

RUN addgroup -S errbit \
  && adduser -S -D -s /bin/false -G errbit -g errbit errbit

# throw errors if Gemfile has been modified since Gemfile.lock
RUN echo "gem: --no-document" >> /etc/gemrc \
  && bundle config --global frozen 1 \
  && bundle config --global clean true \
  && bundle config --global disable_shared_gems false

RUN mkdir -p /app \
  && chown -R errbit:errbit /app \
  && chmod 700 /app/
WORKDIR /app

RUN gem update --system \
  && gem install bundler \
  && apk add --no-cache \
    curl \
    less \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    tzdata

EXPOSE 8080

COPY ["Gemfile", "Gemfile.lock", "/app/"]

RUN apk add --no-cache --virtual build-dependencies \
      build-base \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle install \
      -j "$(getconf _NPROCESSORS_ONLN)" \
      --retry 5 \
      --without test development no_docker \
  && apk del build-dependencies

COPY . /app

RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN chown -R errbit:errbit /app

USER errbit

HEALTHCHECK CMD curl --fail http://localhost:$PORT/users/sign_in || exit 1

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]
