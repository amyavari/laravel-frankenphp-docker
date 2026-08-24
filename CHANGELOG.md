# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Changed

- Exclude AI agent, IDE, and Laravel storage artifacts from the Docker build context

## [1.0.1] - 2026-05-29

### Fixed

- Graceful stops on update for `queue` container
- Graceful stops on update for `schedule` container

## [1.0.0] - 2026-04-06

First stable release of the template, features:

- **Production-ready Docker setup**: Preconfigured for Laravel using FrankenPHP
- **Docker Swarm deployment**: Built-in support for scalable production deployments
- **Caddy reverse proxy**: Automatic HTTPS and domain-based routing
- **CI/CD pipeline**: GitHub Actions for testing, building, deployment, and image cleanup
- **Database support**: PostgreSQL (default) with optional MySQL support
- **Environment & secrets management**: Docker secrets integration for sensitive data
- **Zero-downtime deployment strategy**: Compatible with blue/green deployments
- **Multi-platform builds**: Support for amd64 and arm64 architectures

Optional features:

- **Redis integration**: Ready-to-enable caching, queues, and sessions
- **Laravel Octane support**: High-performance setup using FrankenPHP

[Unreleased]: https://github.com/amyavari/laravel-frankenphp-docker/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/amyavari/laravel-frankenphp-docker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/amyavari/laravel-frankenphp-docker/releases/tag/v1.0.0
