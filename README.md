# Laravel FrankenPHP Docker Template

This repository provides a template for containerizing a Laravel application for both development and production environments.

# Technology Stack

- Docker Swarm
- FrankenPHP (base image)
- Livewire
- PostgreSQL (default) or MySQL
- Caddy (reverse proxy)
- GitHub Actions (CI: automated testing on pull requests and pushes to `main`)
- GitHub Actions (CD: image build and deployment via Docker Swarm on push to `main`)
- GitHub Actions (auto-remove old images from the server and GHCR on push to `main`)
- Redis (optional)
- Laravel Octane (optional)

# Table of Contents

- [Usage and Customization Guide](#usage-and-customization-guide)
  - [Update Base Images](#update-base-images)
  - [Local Development](#local-development)
  - [Continuous Integration (CI)](#continuous-integration-ci)
  - [Production Deployment](#production-deployment)
    - [Environment Variable Configuration](#environment-variable-configuration)
    - [Domain and Access Configuration](#domain-and-access-configuration)
    - [Zero-Downtime Database Migrations](#zero-downtime-database-migrations)
    - [Multi-Platform Support](#multi-platform-support)

- [Other Stack](#other-stack)
  - [Laravel Octane](#laravel-octane)
  - [Redis](#redis)
  - [MySQL](#mysql)

# Usage and Customization Guide

Copy all files and directories from the `./laravel` directory into the root of your Laravel project.

Or run the following commands from the root of your project to clone and copy them automatically:

```bash
 git clone https://github.com/amyavari/laravel-frankenphp-docker.git temp-docker-setup
 cp -rT temp-docker-setup/laravel .
 rm -rf temp-docker-setup
```

## Update Base Images

First, update all Docker base images. The files you should modify:

- `Dockerfile`

```Dockerfile
ARG PHP_VER=<major.minor.patch>
ARG FRANKENPHP_VER=<major.minor.patch>
ARG COMPOSER_VER=<major.minor.patch>
ARG NODE_VER=<major.minor.patch>
ARG DEBIAN_CODENAME=<os>
```

- `compose.prod.yml` (PostgreSQL version):

```yml
db:
  image: postgres:<major.minor-os>
```

**Note:**

- It is recommended to use strict image tags (`MAJOR.MINOR.PATCH-OS`) in production to ensure every deployment uses the exact same images. Therefore, for new projects, change all image tags to the latest stable strict version. See: [Docker Hub](https://hub.docker.com/)
- To reduce storage usage on your server, use the same Linux distribution (Debian codename / OS variant) across all images whenever possible.

## Local Development

For local development, it uses your local `.env` file content, just like a normal local setup.

To run:

```bash
docker compose -f compose.dev.yml up
```

Your application is available on `localhost:8000`

To stop:

```bash
docker compose -f compose.dev.yml down
```

## Continuous Integration (CI)

The CI configuration is already defined in `.github/workflows/ci-cd.yml`.

## Production Deployment

1. Install Docker Engine on your server. See: [Install Docker Engine](https://docs.docker.com/engine/install/)
2. Enable Swarm mode on Docker on the server. If you encounter issues during initialization, refer to: [Create a swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/)

```bash
docker swarm init
```

3. Log in to GitHub Container Registry via Docker on your server. See: [Login via Docker to ghcr.io](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic)

4. Create a directory for your project on the server under `/var/www` using **the same name as your repository**.

### Environment Variable Configuration

1. Place a `.env` file in the server directory without including sensitive data. Set these values to empty or remove them:

```env
APP_KEY=

DB_HOST=
DB_USERNAME=
DB_DATABASE=
DB_PASSWORD=
```

2. Update `DB_USERNAME`, `DB_DATABASE`, `POSTGRES_USER`, and `POSTGRES_DB` in `compose.prod.yml` as required.

3. Store sensitive data such as `APP_KEY` and `DB_PASSWORD` as Docker secrets (names: `app_key` and `db_pass`):

```bash
# You may use Docker contexts with SSH for improved security.
echo "<value>" | docker secret create <name_of_secret> -
```

**Note:** If you choose different names for the secrets, make sure to replace them in all relevant parts of `compose.prod.yml` and in the code snippets in this README where they are used.

If you need additional secrets for other credentials:

1. Suffix the corresponding env with `_FILE` in `compose.prod.yml`.
2. Add the env (without the `_FILE` suffix) in `.docker/scripts/entrypoint.sh` like this:

```bash
file_env "APP_KEY"
```

**Note:** To verify the final environment variables inside the Docker container, use:

```bash
cat /proc/1/environ | tr '\0' '\n'
```

### Domain and Access Configuration

Caddy is used as the reverse proxy and handles SSL.

Copy the `./reverse-proxy` directory to your local machine.

Or run the following commands to clone and copy it automatically:

```bash
 git clone https://github.com/amyavari/laravel-frankenphp-docker.git temp-docker-setup
 cp -rT temp-docker-setup/reverse-proxy ./reverse-proxy
 rm -rf temp-docker-setup
```

**Note:** If the reverse proxy is used for multiple projects, it is recommended to maintain it in a separate repository. Otherwise, you can include it in your current project repository.

1. Edit `reverse-proxy/conf/Caddyfile`:
   - If required, duplicate the existing configuration block for each additional application.
   - Replace `<full_domain_name>` with your actual domain or subdomain.
   - Replace `<app_service_name>` with your **repository name**.

2. Update Caddy image version in `reverse-proxy/compose.prod.yml`.

```yml
caddy:
  image: caddy:<major.minor.patch-os>
```

3. Deploy on the Server
   - Create a directory on the server under `/var/www/`.
   - Copy all files and directories from `./reverse-proxy` into this directory.
   - Create a shared overlay network in the Swarm:

   ```bash
   docker network create --driver overlay --attachable web
   ```

   - Deploy the Caddy container:

   ```bash
   cd /var/www/<revers_proxy_directory>
   docker stack deploy -c compose.prod.yml proxy -d
   ```

**The application is now ready to be pushed to GitHub and will become accessible after deployment completes.**

### Zero-Downtime Database Migrations

The services in this repository are designed to leverage Docker Swarm blue/green updates to support zero-downtime deployments.

However, database migrations cannot always be safely rolled back. If your migrations include breaking schema changes, consider using the [Expand and Contract pattern for schema changes](https://www.prisma.io/dataguide/types/relational/expand-and-contract-pattern).

Alternatively, you can handle it manually by:

1. Bring the application down.
2. Back up the database.
3. Deploy the new schema and application version (using the normal CI/CD pipeline of this repository).
4. Verify stability, then bring the application back up.

### Multi-Platform Support

**Linux amd64**

The current CI/CD workflow builds Docker images for `linux/amd64`.

**Linux arm64**

To build and test for `linux/arm64`, update the `runs-on:` value for both the `test` and `build` jobs in `.github/workflows/ci-cd.yml`:

```yml
jobs:
  test:
    runs-on: ubuntu-latest-arm
    # Others remain unchanged

  build:
    runs-on: ubuntu-latest-arm
    # Others remain unchanged
```

**Linux amd64 and arm64**

To support both platforms, make the following changes in `.github/workflows/ci-cd.yml`:

1. In the `build` job, add the **Set up QEMU** step immediately after the **Checkout repository** step:

```yml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4

  - name: Set up QEMU # Add this step
    uses: docker/setup-qemu-action@v3
```

2. Add `platforms: linux/amd64,linux/arm64` to the **Build and push image (with shared cache)** step in the `build` job:

```yml
- name: Build and push image (with shared cache)
  uses: docker/build-push-action@v6
  with:
    # Others remain unchanged
    platforms: linux/amd64,linux/arm64
```

# Other Stack

## Laravel Octane

First, install [Laravel Octane](https://laravel.com/docs/12.x/octane) in your project:

```bash
composer require laravel/octane

php artisan octane:install --server=frankenphp
```

**Note:** You don't need to install the FrankenPHP binary on your local machine, as everything runs inside the Docker container.

Then, add the following to the `app` service in your `compose.prod.yml`:

```yml
services:
  app:
    # All other configurations remain unchanged.
    command: php artisan octane:frankenphp --host=0.0.0.0 --port=80
```

## Redis

First, add Redis to `compose.prod.yml`.

1. Add `REDIS_HOST: redis` (or any desired service name) to the `x-environment` section:

```yml
x-environment: ...
  # Existing environment variables
  REDIS_HOST: redis
```

2. Add `redis_data` (or any desired volume name) to the `volumes` section:

```yml
volumes:
  # Existing volumes
  redis_data:
```

3. Add the `redis` service (or the name you chose in step 1).

```yml
services:
  # Existing services

  redis:
    image: redis:<major.minor.patch-os> # Set this
    volumes:
      - redis_data:/data # Update this if is required
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    deploy:
      replicas: 1
      restart_policy:
        condition: any
        delay: 5s
        max_attempts: 0
    networks:
      - net
```

**Notes:**

- Set Redis image version.
- Update the `volumes` value with the name you chose in step 2 if you used a different name than the suggested one.

Then, uncomment this section in `.docker/scripts/entrypoint.sh` (remove `#` from the lines):

```bash
# log "Waiting for Redis..."
# ./wait-for-it.sh "${REDIS_HOST:-redis}:${REDIS_PORT:-6379}" --timeout=60 --strict
# log "Redis is ready"
```

Now, you can configure cache, queue, and other drivers to use Redis in your `.env` file:

```env
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
BROADCAST_CONNECTION=redis
```

## MySQL

If you want to use MySQL instead of PostgreSQL, update the following in `compose.prod.yml`:

1. Change `DB_USERNAME` in the `x-environment` section to `root`:

```yml
x-environment: ...
  # Other environment variables
  DB_USERNAME: root
  # Other environment variables
```

2. Replace the existing `db` service entirely with the MySQL configuration below (copy and paste all of it):

```yml
db:
  image: mysql:<major.minor.patch-os> # Set this
  environment:
    MYSQL_DATABASE: db-name # Update this
    MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_pass
  volumes:
    - db_data:/var/lib/mysql
  healthcheck:
    test:
      [
        "CMD-SHELL",
        "mysqladmin ping -h 127.0.0.1 -u root -p$$(cat /run/secrets/db_pass) --silent",
      ]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 30s
  deploy:
    replicas: 1
    restart_policy:
      condition: on-failure
      delay: 5s
      max_attempts: 0
  networks:
    - net
  secrets:
    - db_pass
```

**Notes:**

- Set MySQL image version.
- Update `MYSQL_DATABASE` to match the database name you defined in [Environment Variable Configuration](#environment-variable-configuration)
