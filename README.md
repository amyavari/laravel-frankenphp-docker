# Laravel FrankenPHP Docker Template

This repository provides a template for containerizing a Laravel application for both development and production environments.

# Technology Stack

- Docker Swarm
- FrankenPHP (base image)
- Livewire
- PostgreSQL
- Caddy (reverse proxy)
- GitHub Actions (CI: automated testing on pull requests and merges to `main`)
- GitHub Actions (CD: image build and deployment via Docker Swarm on merge to `main`)
- GitHub Actions (auto-remove old images from the server and GHCR on merge to `main`)
- Redis (optional)
- Laravel Octane (optional)

**Note:** It is recommended to use strict image tags in production to ensure every deployment uses the exact same images. Therefore, for new projects, change all image tags to the latest stable strict version. See: [Docker Hub](https://hub.docker.com/)

# Usage and Customization Guide

Copy all files and directories from the `./laravel` directory into the root of your Laravel project.

## Local Development

For local development, it uses your local `.env` file content, just like a normal local setup.

Update the `<>` placeholders in `compose.dev.yml`.

To run:

```bash
docker compose up -f compose.dev.yml
```

Your application is available on `localhost:8000`

To stop:

```bash
docker compose down -f compose.dev.yml
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

4. Create a directory for your project on the server under `/var/www`.
5. Update `cd /var/www/<app_directory>` in `.github/workflows/ci-cd.yml` to match your path.
6. Update `<app_service_name>` in the `docker stack deploy -c compose.prod.yml <app_service_name> --with-registry-auth -d` command in `.github/workflows/ci-cd.yml` to your desired app service name.

### Environment Variable Configuration

1. Place a `.env` file in the server directory without including sensitive data. Set these values to empty or remove them:

```env
APP_KEY=
APP_ENV=
APP_DEBUG=
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

Place updated `compose.prod.yml` file in the application directory on the server.

### Domain and Access Configuration

Caddy is used as the reverse proxy and handles SSL.

Edit `reverse-proxy/conf/Caddyfile`:

1. If required, duplicate the existing configuration block for each additional application.
2. Update the `<>` placeholders.

Create a directory on the server under `/var/www/`.

Copy all files and directories from `reverse-proxy` into this directory.

Next, create a shared overlay network in the Swarm:

```bash
docker network create --driver overlay --attachable web
```

Deploy the Caddy container:

```bash
cd /var/www/<revers_proxy_directory>
docker stack deploy -c compose.prod.yml proxy -d
```

**The application is now ready to be pushed to GitHub and will become accessible after deployment completes.**

# Other Stack

## Laravel Octane

First, install [Laravel Octane](https://laravel.com/docs/12.x/octane) in your project:

```bash
composer require laravel/octane

php artisan octane:install --server=frankenphp
```

Then, add the following to the `app` service in your `compose.prod.yml`:

```yml
services:
  app:
    # All other configurations remain unchanged.
    command: php artisan octane:frankenphp --host=0.0.0.0 --port=80
```
