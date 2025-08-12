#!/bin/bash
set -e

echo "Starting Kimai on Railway..."

# Check if DATABASE_URL is set (Railway will provide this)
if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL not set, exiting..."
    exit 1
fi

echo "Database URL is configured"

# Set default environment variables if not provided
export TRUSTED_HOSTS=${TRUSTED_HOSTS:-"localhost,127.0.0.1,*.up.railway.app"}
export APP_ENV=${APP_ENV:-"prod"}
export APP_SECRET=${APP_SECRET:-$(openssl rand -base64 32)}
export MAILER_URL=${MAILER_URL:-"null://localhost"}

# Create admin user if it doesn't exist
create_admin() {
    echo "Checking for admin user..."
    if ! /opt/kimai/bin/console kimai:user:list | grep -q admin; then
        echo "Creating admin user..."
        echo "admin123" | /opt/kimai/bin/console kimai:user:create admin admin@example.com ROLE_SUPER_ADMIN --no-interaction || true
    else
        echo "Admin user already exists"
    fi
}

# Start the original entrypoint in the background
echo "Starting Kimai installation..."
/entrypoint.sh &
KIMAI_PID=$!

# Wait for Kimai to start
sleep 30

# Try to create admin user (this might fail if database isn't ready, that's ok)
create_admin || echo "Could not create admin user yet, will try later"

# Wait for the main process
wait $KIMAI_PID
