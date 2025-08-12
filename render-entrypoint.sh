#!/usr/bin/env bash
set -euo pipefail

# Ensure Apache binds to the port Render provides
PORT="${PORT:-8001}"

# Reconfigure Apache to listen on $PORT if configs exist
if [ -f /etc/apache2/ports.conf ]; then
  sed -i -E "s/^Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf || true
fi
if [ -f /etc/apache2/sites-available/000-default.conf ]; then
  sed -i -E "s#<VirtualHost \*:[0-9]+>#<VirtualHost *:${PORT}>#g" /etc/apache2/sites-available/000-default.conf || true
fi
if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  sed -i -E "s#<VirtualHost \*:[0-9]+>#<VirtualHost *:${PORT}>#g" /etc/apache2/sites-enabled/000-default.conf || true
fi

# Hand off to the original Kimai entrypoint (handles DB readiness, migrations, etc.)
exec /entrypoint.sh
