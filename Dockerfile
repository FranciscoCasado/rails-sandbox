FROM ruby:2.7.5-slim-bullseye

# Will not get prompted for input
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install base dependencies
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    apt-utils gnutls-bin build-essential postgresql-client curl libpq-dev\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node & yarn
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update -qq && apt-get install -yq --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn@1.22.19

# Gem install
RUN gem install bundler:2.4.3 --conservative

# Set Working directory
WORKDIR /src


# Install yarn dependencies
COPY ./package.json ./yarn.lock ./
RUN yarn install --frozen-lockfile

# Install ruby dependencies
COPY ./Gemfile ./Gemfile.lock /src/
COPY ./gems ./gems
RUN bundle install --retry=3
RUN bundle clean --force

# Run the project
COPY . /src

CMD ["/src/devops/entrypoint.sh"]
