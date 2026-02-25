#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf "\n[entrypoint] %s\n" "$1"
}

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"

	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		log "Both $var and $fileVar are set (but are exclusive)"
	fi

	local val="$def"

	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi

	export "$var"="$val"
	unset "$fileVar"
}

optimize_laravel() {
  php artisan optimize
}

log "Setting environment variables from secret files..."
file_env "APP_KEY"
file_env "DB_PASSWORD"
log "Environment variables loaded"

log "Waiting for database..."
./wait-for-it.sh "${DB_HOST:-db}:${DB_PORT:-5432}" --timeout=60 --strict
log "Database is ready"

# log "Waiting for Redis..."
# ./wait-for-it.sh "${REDIS_HOST:-redis}:${REDIS_PORT:-6379}" --timeout=60 --strict
# log "Redis is ready"

log "Running Laravel optimize..."
optimize_laravel
log "Laravel optimization completed"

exec "$@"