FROM ruby:2.2

RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

EXPOSE 80

CMD ruby ./whoisbot.rb -sv -e prod -p 80

