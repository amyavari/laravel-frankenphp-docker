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

RUN apt-get update && apt-get install -y --no-install-recommends \
    zip \
    unzip \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions \
    bcmath \
    ctype \
    exif \
    fileinfo \
    intl \
    mbstring \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    redis \
    sockets \
    redis

# Dev Builder
FROM base AS dev-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions \
    gd \
    pcov

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/local /usr/local

# Development
FROM dev-builder AS dev

ENV APP_ENV=local
ENV APP_DEBUG=true

CMD ["sh", "-c", "npm run dev -- --host & exec frankenphp php-server --root=/app/public"]

# Test
FROM dev-builder AS test

ENV APP_ENV=testing
ENV APP_DEBUG=false
ENV DB_CONNECTION=sqlite
ENV CACHE_DRIVER=array
ENV SESSION_DRIVER=array
ENV QUEUE_CONNECTION=sync
ENV MAIL_MAILER=log

COPY composer.json composer.lock ./
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --no-scripts

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN php artisan package:discover --ansi

RUN cp .env.example .env \
    && php artisan key:generate --force

RUN npm run build

RUN mkdir -p database \
    && touch database/database.sqlite

RUN php artisan migrate --force

CMD ["php", "artisan", "test"]

# Production Vendor
FROM  composer AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# Production Frontend
FROM node AS frontend

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY --from=vendor /app/vendor ./vendor

COPY . .

RUN npm run build

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

COPY --from=vendor /app/vendor ./vendor
COPY --from=frontend /app/public/build ./public/build

COPY . .

RUN php artisan package:discover --ansi

RUN chown -R ${USER}:${USER} .

USER ${USER}

ENTRYPOINT ["./entrypoint.sh"]

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]