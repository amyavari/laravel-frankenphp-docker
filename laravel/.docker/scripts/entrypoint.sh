#!/usr/bin/env bash
set -Eeuo pipefail

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"

	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo "Both $var and $fileVar are set (but are exclusive)"
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

echo "Setting environments..."
file_env "APP_KEY"
file_env "DB_PASSWORD"
echo "Environments have been set."

echo "Waiting for database..."
./wait-for-it.sh "${DB_HOST:-db}:${DB_PORT:-5432}" --timeout=60 --strict
echo "Database is up."

echo "Running Laravel optimize..."
optimize_laravel
echo "Laravel optimize has been run..."

exec "$@"