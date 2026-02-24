# Laravel FrankenPHP Docker Template

This repository provides a template for containerizing a Laravel application for both development and production environments.

# Technology Stack

- Docker Swarm
- FrankenPHP (base image)
- Livewire
- PostgreSQL
- GitHub Actions (CI: automated testing on pull requests and merges to `main`)
- GitHub Actions (CD: image build and deployment via Docker Swarm on merge to `main`)
- Redis (optional)
- Laravel Octane (optional)
- Caddy (reverse proxy, optional)

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
6. Update `<app_service_name>` in the final line of `.github/workflows/ci-cd.yml` to your desired app service name.

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

### Domain and Access Configuration

For production, you have two choices:

1. Single application on a server
2. Multiple applications on a single server

#### Single Application on a Server

In this scenario, a reverse proxy is not required.

Edit `compose.prod.yml`:

1. Remove the `web` network from the `app` service and from the `networks` section.
2. Remove `SERVER_NAME: :80` from the `app` service environment.
3. Expose ports `80` and `443`.

Your `app` service and `networks` should look like this:

```yml
services:
  app:
    image: *app-image
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    env_file:
      - .env
    environment: *environment
    volumes:
      - storage:/app/storage
    # All other configurations remain unchanged.

networks:
  net:
```

Put this `compose.prod.yml` file in the server directory.

**The application is now ready to be pushed to GitHub and will become accessible after deployment completes.**

### Multiple Applications on a Single Server

In this scenario, Caddy is used as a reverse proxy.

Edit `reverse-proxy/conf/Caddyfile`:

1. Duplicate the existing configuration block for each additional application.
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

Place the updated `compose.prod.yml` file from [Environment Variable Configuration](#environment-variable-configuration) in the application directory on the server.

**The application is now ready to be pushed to GitHub and will become accessible after deployment completes.**
