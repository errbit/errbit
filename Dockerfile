FROM ubuntu
RUN apt-get update
ADD . /errbit
WORKDIR /errbit

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  ca-certificates gcc git make node ruby-dev ruby && \
  cd /errbit && gem install bundler && bundle install && \
  DEBIAN_FRONTEND=noninteractive apt-get -y purge gcc git make ruby-dev && \
  DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

RUN env > /myenv

CMD ["bundle", "exec", "foreman", "start"]
