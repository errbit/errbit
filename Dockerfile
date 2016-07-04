FROM alpine:3.4
MAINTAINER David Papp <david@ghostmonitor.com>


RUN apk --update add \
  build-base ruby-dev libc-dev linux-headers \
  libffi-dev zlib-dev \
  ca-certificates \
  ruby \
  ruby-bundler \
  ruby-io-console \
  ruby-bigdecimal \
  curl \
  bash \
  nodejs \
  tzdata \
  ruby-dev && \
  rm -fr /usr/share/ri
COPY . /app
RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers \
    openssl-dev postgresql-dev libxml2-dev libxslt-dev
RUN cd app && \
bundle config build.nokogiri --use-system-libraries && \
bundle install --without test development no_docker && \
bundle exec rake assets:precompile

WORKDIR /app

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]
