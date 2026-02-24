ARG PHP_VER=8.5.2
ARG FRANKENPHP_VER=1.11.1
ARG COMPOSER_VER=2.9.5
ARG NODE_VER=25.6.1

FROM dunglas/frankenphp:${FRANKENPHP_VER}-php${PHP_VER}-trixie AS php
FROM composer:${COMPOSER_VER} AS composer
FROM node:${NODE_VER}-trixie AS node

# Base
FROM php AS base

WORKDIR /app

RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    libsqlite3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions \
    mbstring \
    pcntl \
    bcmath \
    zip \
    intl \
    opcache \
    pdo_sqlite \
    pdo_pgsql \
    sockets

# Only if we have tests on images and fake images on Laravel (Mix these to above layers)
# RUN apt-get update && apt-get install -y \
#     libpng-dev libjpeg-dev libfreetype6-dev libwebp-dev \
#     && rm -rf /var/lib/apt/lists/*
#
# RUN install-php-extensions gd

# If you have Redis
# RUN pecl install redis-${REDIS_VER} && docker-php-ext-enable redis

# Dev Builder
FROM base AS dev-builder

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/local /usr/local

RUN pecl install pcov \
    && docker-php-ext-enable pcov

# Dev
FROM dev-builder AS dev

ENV APP_ENV=local
ENV APP_DEBUG=true

CMD ["sh", "-c", "npm run dev -- --host & exec frankenphp run --watch"]

# Test
FROM dev-builder AS test

ENV APP_ENV=testing
ENV APP_DEBUG=false
ENV DB_CONNECTION=sqlite
ENV CACHE_DRIVER=array
ENV SESSION_DRIVER=array
ENV QUEUE_CONNECTION=sync
ENV MAIL_MAILER=log

COPY . .

RUN mkdir -p database \
    && touch database/database.sqlite

RUN composer install --no-interaction --prefer-dist

RUN cp .env.example .env \
    && php artisan key:generate --force

RUN npm ci \
    && npm run build

RUN php artisan migrate --force

CMD ["php", "artisan", "test"]

# Production Vendor
FROM  composer AS vendor

WORKDIR /app

COPY . .

RUN composer install --no-dev --no-interaction --optimize-autoloader

# Production Frontend
FROM node AS frontend

WORKDIR /app

COPY --from=vendor ./app .

RUN npm ci \
    && npm run build

# Production
FROM base AS prod

ENV APP_ENV=production
ENV APP_DEBUG=false

ARG USER=appuser
ARG UID=1010

RUN groupadd -g ${UID} ${USER} && \
    useradd -u ${UID} -g ${USER} -m ${USER};

RUN setcap -r /usr/local/bin/frankenphp; \
    chown -R ${USER}:${USER} /config/caddy /data/caddy

COPY .docker/scripts/entrypoint.sh entrypoint.sh
COPY .docker/scripts/wait-for-it.sh wait-for-it.sh
RUN chmod +x entrypoint.sh wait-for-it.sh

COPY --from=vendor /app .
COPY --from=frontend /app/public/build ./public/build

RUN chown -R ${USER}:${USER} /app

USER ${USER}

ENTRYPOINT ["./entrypoint.sh"]

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]