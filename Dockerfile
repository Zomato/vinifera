FROM ruby:2.6.6-alpine

RUN apk update && apk add bash build-base postgresql-dev tzdata busybox-extras redis


RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.1.4 --no-document

COPY . .

ENTRYPOINT ["/bin/bash","./sidekiq_docker_boot.sh"]