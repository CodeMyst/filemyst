FROM ruby:3.3-alpine

WORKDIR /app
COPY Gemfile Gemfile.lock /app/

RUN bundle install

COPY . /app/

ENV APP_ENV=production

ENTRYPOINT [ "ruby", "./lib/app.rb" ]
