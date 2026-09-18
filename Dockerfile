# syntax=docker/dockerfile:1

ARG RUBY_VERSION=4.0.1
ARG NODE_MAJOR=22

FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

ARG NODE_MAJOR

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_LOG_TO_STDOUT=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config \
      postgresql-client \
      ca-certificates \
      gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app

FROM base AS development

ENV RAILS_ENV=development \
    NODE_ENV=development \
    IN_DOCKER=1 \
    BINDING=0.0.0.0

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 3000 3036
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/dev"]

FROM base AS build

ENV RAILS_ENV=production \
    NODE_ENV=production \
    BUNDLE_WITHOUT=development:test

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev=false

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec vite build && \
    SECRET_KEY_BASE_DUMMY=1 bundle exec bootsnap precompile app/ lib/

FROM base AS production

ENV RAILS_ENV=production \
    NODE_ENV=production \
    BUNDLE_WITHOUT=development:test \
    IN_DOCKER=1

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

EXPOSE 3000
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/thrust", "./bin/rails", "server", "-b", "0.0.0.0"]
