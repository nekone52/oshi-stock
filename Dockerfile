FROM ruby:3.3.12

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs postgresql-client

WORKDIR /app

COPY Gemfile Gemfile.lock /app/

RUN bundle install

COPY . /app
