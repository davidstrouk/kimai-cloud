#!/usr/bin/env bash
set -euo pipefail

# Bind Apache to the Render-provided PORT
PORT="${PORT:-8001}"
if [ -f /etc/apache2/ports.conf ]; then
  sed -i -E "s/^Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf || true
fi
if [ -f /etc/apache2/sites-available/000-default.conf ]; then
  sed -i -E "s#<VirtualHost \*:[0-9]+>#<VirtualHost *:${PORT}>#g" /etc/apache2/sites-available/000-default.conf || true
fi
if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  sed -i -E "s#<VirtualHost \*:[0-9]+>#<VirtualHost *:${PORT}>#g" /etc/apache2/sites-enabled/000-default.conf || true
fi

# Minimal diagnostics (mask sensitive info)
echo "[render-entrypoint] Using PORT=${PORT}"
if [ -n "${DATABASE_URL:-}" ]; then
  # Extract host and db name for visibility
  _db_host=$(echo "$DATABASE_URL" | sed -E 's|^[a-zA-Z0-9+.-]+://[^@]*@([^/:?]+).*|\1|')
  _db_name=$(echo "$DATABASE_URL" | sed -E 's|^[a-zA-Z0-9+.-]+://[^/]+/([^/?#]+).*|\1|')
  echo "[render-entrypoint] DATABASE_URL present (host=${_db_host}, db=${_db_name})"
else
  echo "[render-entrypoint] WARNING: DATABASE_URL is empty"
fi

ADMIN_USER=${KIMAI_ADMIN_USER:-admin}
ADMIN_EMAIL=${KIMAI_ADMIN_EMAIL:-admin@example.com}
ADMIN_PASSWORD=${KIMAI_ADMIN_PASSWORD:-}

create_or_reset_admin() {
  local tries=0
  local max_tries=${ADMIN_RETRIES:-60}
  local wait_sec=${ADMIN_WAIT_SECONDS:-5}

  db_ready() {
    /opt/kimai/bin/console doctrine:query:sql "SELECT 1" >/dev/null 2>&1
  }

  while [ $tries -lt $max_tries ]; do
    tries=$((tries+1))
    # Ensure console is callable and DB is ready for console commands
    if /opt/kimai/bin/console -V >/dev/null 2>&1 && db_ready; then
      # Does the user exist?
      if /opt/kimai/bin/console kimai:user:list 2>/dev/null | awk '{print $1}' | grep -q "^${ADMIN_USER}$"; then
        echo "[render-entrypoint] Admin '${ADMIN_USER}' exists"
        # Ensure user is active
        /opt/kimai/bin/console kimai:user:activate "$ADMIN_USER" >/dev/null 2>&1 || true
        if [ -n "$ADMIN_PASSWORD" ]; then
          # Try argument-based reset first
          if out=$(/opt/kimai/bin/console kimai:user:reset-password "$ADMIN_USER" "$ADMIN_PASSWORD" 2>&1); then
            echo "[render-entrypoint] Admin password reset"
            return 0
          else
            echo "[render-entrypoint] ERROR during reset-password (args): $out"
            # Fallback: interactive reset by piping password twice
            if out=$(printf "%s\n%s\n" "$ADMIN_PASSWORD" "$ADMIN_PASSWORD" | \
                     /opt/kimai/bin/console kimai:user:reset-password "$ADMIN_USER" 2>&1); then
              echo "[render-entrypoint] Admin password reset (interactive fallback)"
              return 0
            else
              echo "[render-entrypoint] ERROR during reset-password (interactive): $out"
            fi
          fi
        fi
      else
        echo "[render-entrypoint] Creating admin '${ADMIN_USER}'"
        # Prefer interactive create by piping password twice (works across Kimai versions)
        if [ -n "$ADMIN_PASSWORD" ]; then
          if out=$(printf "%s\n%s\n" "$ADMIN_PASSWORD" "$ADMIN_PASSWORD" | \
                   /opt/kimai/bin/console kimai:user:create "$ADMIN_USER" "$ADMIN_EMAIL" ROLE_SUPER_ADMIN 2>&1); then
            /opt/kimai/bin/console kimai:user:activate "$ADMIN_USER" >/dev/null 2>&1 || true
            echo "[render-entrypoint] Admin created"
            return 0
          else
            echo "[render-entrypoint] ERROR during user:create (interactive): $out"
          fi
        else
          echo "[render-entrypoint] WARNING: KIMAI_ADMIN_PASSWORD not set; cannot create admin"
        fi
      fi
    fi
    echo "[render-entrypoint] Admin setup attempt ${tries}/${max_tries} failed; retrying in ${wait_sec}s"
    sleep "$wait_sec"
  done
  echo "[render-entrypoint] Admin setup did not complete after ${max_tries} attempts"
  return 1
}

# Start the original Kimai entrypoint in background (handles DB readiness, migrations, Apache)
/entrypoint.sh &
KIMAI_PID=$!

# Give Kimai a head start before attempting admin ops (allow DB migrations)
sleep 20
create_or_reset_admin || true

# Wait for the main process
wait "$KIMAI_PID"
