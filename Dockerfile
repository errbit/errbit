FROM ruby:2.5.1-alpine
LABEL maintainer="David Papp <david@ghostmonitor.com>"

WORKDIR /app
# throw errors if Gemfile has been modified since Gemfile.lock
RUN echo "gem: --no-document" >> /etc/gemrc \
  && bundle config --global frozen 1 \
  && bundle config --global clean true \
  && bundle config --global disable_shared_gems false \
  && gem update --system 2.7.4 \
  && gem install bundler --version 1.16.1 \
  && apk add --no-cache \
    curl \
    less \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    tzdata


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

RUN RAILS_ENV=production bundle exec rake assets:precompile \
  && rm -rf /app/tmp/* \
  && chmod 777 /app/tmp

EXPOSE 8080

HEALTHCHECK CMD curl --fail "http://$(/bin/hostname -i | /usr/bin/awk '{ print $1 }'):8080/users/sign_in" || exit 1

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]
