FROM ruby:3.2

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

WORKDIR /usr/src/app

# Dependencias de compilación para Nokogiri, Protobuf y demás gems nativas
RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       libxml2-dev \
                       libxslt1-dev \
                       zlib1g-dev \
                       liblzma-dev \
                       pkg-config \
                       autoconf \
                       automake \
                       libtool \
                       protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

# Evitar warning de git
RUN git config --global --add safe.directory /usr/src/app

# Copiar gemspec y Gemfile
COPY Gemfile Gemfile.lock just-the-docs.gemspec ./

# Instalar bundler y gems
RUN gem install bundler && bundle install

EXPOSE 4000