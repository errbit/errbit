FROM ruby:2.3.3-alpine
MAINTAINER David Papp <david@ghostmonitor.com>

WORKDIR /app

RUN gem update --system && gem install bundler && apk add --update --no-cache build-base less libxml2-dev libxslt-dev nodejs tzdata

EXPOSE 8080

COPY Gemfile Gemfile.lock /app/

RUN bundle config build.nokogiri --use-system-libraries && \
    bundle install --jobs 8 --retry 5 --without test development no_docker

COPY . /app
RUN RAILS_ENV=production bundle exec rake assets:precompile

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]
