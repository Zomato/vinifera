FROM ruby:2.6.6

RUN apt-get update && apt-get install git libgit2-dev libpq-dev tini cron -y && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.1.4 --no-document

RUN bundle config set force_ruby_platform true

COPY . .

ENTRYPOINT ["/bin/bash","./sidekiq_docker_boot.sh"]